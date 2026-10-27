<?php
declare(strict_types=1);
// Run once daily using Windows Task Scheduler or cron after configuring mail() and optional Twilio.
if (PHP_SAPI !== 'cli') {
  http_response_code(404);
  exit;
}
$config=require __DIR__.'/config.php';
$dsn="mysql:host={$config['db_host']};dbname={$config['db_name']};charset={$config['db_charset']}";
$pdo=new PDO($dsn,$config['db_user'],$config['db_password'],[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
function sendSms(array $c,string $to,string $body): bool {
  if(empty($c['twilio_account_sid'])||empty($c['twilio_auth_token'])||empty($c['twilio_from_number'])||!function_exists('curl_init')) return false;
  $url='https://api.twilio.com/2010-04-01/Accounts/'.$c['twilio_account_sid'].'/Messages.json';
  $ch=curl_init($url); curl_setopt_array($ch,[CURLOPT_POST=>true,CURLOPT_POSTFIELDS=>http_build_query(['To'=>$to,'From'=>$c['twilio_from_number'],'Body'=>$body]),CURLOPT_USERPWD=>$c['twilio_account_sid'].':'.$c['twilio_auth_token'],CURLOPT_RETURNTRANSFER=>true,CURLOPT_TIMEOUT=>20]);
  $out=curl_exec($ch); $status=(int)curl_getinfo($ch,CURLINFO_HTTP_CODE); curl_close($ch); return $out!==false&&$status>=200&&$status<300;
}
function logNotice(PDO $pdo,string $uid,string $type,string $title,string $message,string $channel,string $status): void {
  $q=$pdo->prepare('INSERT IGNORE INTO notifications(user_id,notification_type,title,message,channel,delivery_status,notification_date) VALUES(?,?,?,?,?,?,CURDATE())');
  $q->execute([$uid,$type,$title,$message,$channel,$status]);
}
$users=$pdo->query('SELECT u.id,u.full_name,u.email,p.phone_number,p.email_enabled,p.sms_enabled,p.daily_reminder_enabled,p.balance_alert_enabled,p.low_balance_threshold FROM users u LEFT JOIN notification_preferences p ON p.user_id=u.id')->fetchAll();
foreach($users as $u){
  $daily=($u['daily_reminder_enabled']??1)==1;
  $q=$pdo->prepare("SELECT COALESCE(SUM(CASE WHEN type=0 AND is_deleted=0 THEN amount ELSE 0 END),0) income,COALESCE(SUM(CASE WHEN type=1 AND is_deleted=0 THEN amount ELSE 0 END),0) expense FROM transactions WHERE user_id=? AND transaction_date>=CURDATE() AND transaction_date<DATE_ADD(CURDATE(),INTERVAL 1 DAY)");$q->execute([$u['id']]);$today=$q->fetch();
  $q=$pdo->prepare("SELECT COALESCE(SUM(CASE WHEN type=0 AND is_deleted=0 THEN amount ELSE 0 END),0)-COALESCE(SUM(CASE WHEN type=1 AND is_deleted=0 THEN amount ELSE 0 END),0) balance FROM transactions WHERE user_id=?");$q->execute([$u['id']]);$balance=(float)$q->fetchColumn();
  if($daily){
    $msg=((float)$today['income']===0.0&&(float)$today['expense']===0.0)?'Remember to record today\'s income and expenses in Student Expense Manager.':'Today so far: income '.number_format((float)$today['income'],2).', expenses '.number_format((float)$today['expense'],2).'. Current balance: '.number_format($balance,2).'.';
    logNotice($pdo,$u['id'],'daily_reminder','Daily money check-in',$msg,'in_app','sent');
    if(($u['email_enabled']??1)==1){$ok=mail($u['email'],'Student Expense Manager: daily money check-in',$msg,'From: '.$config['email_from']);logNotice($pdo,$u['id'],'daily_reminder','Daily money check-in',$msg,'email',$ok?'sent':'failed');}
    if(($u['sms_enabled']??0)==1&&!empty($u['phone_number'])){$ok=sendSms($config,$u['phone_number'],$msg);logNotice($pdo,$u['id'],'daily_reminder','Daily money check-in',$msg,'sms',$ok?'sent':(empty($config['twilio_account_sid'])?'not_configured':'failed'));}
  }
  if(($u['balance_alert_enabled']??1)==1 && $balance <= (float)($u['low_balance_threshold']??0)){
    $msg='Balance alert: your recorded balance is '.number_format($balance,2).'. Review your recent transactions and budget.';
    logNotice($pdo,$u['id'],'balance_alert','Account balance alert',$msg,'in_app','sent');
    if(($u['email_enabled']??1)==1){$ok=mail($u['email'],'Student Expense Manager: balance alert',$msg,'From: '.$config['email_from']);logNotice($pdo,$u['id'],'balance_alert','Account balance alert',$msg,'email',$ok?'sent':'failed');}
    if(($u['sms_enabled']??0)==1&&!empty($u['phone_number'])){$ok=sendSms($config,$u['phone_number'],$msg);logNotice($pdo,$u['id'],'balance_alert','Account balance alert',$msg,'sms',$ok?'sent':(empty($config['twilio_account_sid'])?'not_configured':'failed'));}
  }
}
echo "Daily notification run completed\n";
