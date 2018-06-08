#!c:/Perl/bin/Perl.exe
require "ctnlib/golden/common.pl";
require "ctnlib/golden/html.pl";
require "ctnlib/golden/datelib.pl";
require "ctnlib/golden/manage.pl";
require "ctnlib/golden/cgi-lib.pl";
require "ctnlib/golden/air_pay.pl";
require "ctnlib/golden/air_pay_op.pl";
require "ctnlib/golden/my_sybperl.pl";

use Sybase::CTlib;

## =====================================================================
## start program
## ---------------------------------------------------------------------
&ReadParse();
## ---------------------------------------
## Print Html header,use Html.pl
## ---------------------------------------
&HTMLHead();
&Title("火车票财务收银");
## =====================================================================
$Corp_ID = ctn_auth("T008");
if(length($Corp_ID) == 1) { exit; }
##获取当前的时间
$today = &cctime(time);
($week,$month,$day,$time,$year)=split(" ",$today);
if($day<10){$day="0".$day;}
$today = $year.".".$month."."."$day";
## ===============================================================================
&get_op_type();
## 获取送票员信息　
$s_list = "<option value=''>---全部送票员---</option><option value='%'>无送票员</option>";
$sql =" select rtrim(User_ID),User_name from ctninfo..User_info 
	where Corp_num='$Corp_center' and User_type = 'Y' ";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if ($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			$user_name{$row[0]}=$row[1];
			if ($in{Sender} eq $row[0]) {
				$s_list .= "<option value=$row[0] selected>$row[0]　$row[1]</option>";
			}
			else{
				$s_list .= "<option value=$row[0]>$row[0]　$row[1]</option>";
			}	
		}
	}
}
##批量收银
if ($in{action} eq "W") {
	my %m_type = &get_dict($Corp_center,1,"","hash");
	##获取会计科目的信息哈希组
	my %kemu_hash = &get_kemu($Corp_center,"","hash2","","","","assist","N");
	my @pay_method=();
	$in{pay_method_num}=sprintf("%.0f",$in{pay_method_num});
	if ($in{pay_method_num}<1) {$in{pay_method_num}=1;}
	for (my $p=0;$p<$in{pay_method_num} ;$p++) {##多种付款科目	fanzy@2015-04-17
		my $pp=($p==0)?"":"_$p";
		my %pay_method_info=();
		$pay_method_info{pay_method}=$in{"pay_method".$pp};			#付款科目
		$pay_method_info{Pay_type2}=$in{"Pay_type2".$pp};		#核算项目
		$pay_method_info{ReferNo}=$in{"ReferNo".$pp};			#交易参考号
		$pay_method_info{BankName}=$in{"BankName".$pp};			#发卡行
		$pay_method_info{ReOp_date}=$in{"ReOp_date".$pp};		#交易日期
		$pay_method_info{BankCardNo}=$in{"BankCardNo".$pp};		#卡号后四位
		$pay_method_info{Pay_Recv_total}=$in{"Pay_Recv_total".$pp};		#付款科目实收
		$pay_method_info{Pay_Recv_total_copy}=$in{"Pay_Recv_total".$pp};		#付款科目实收备份，赊销款扣款用到，防止减去转存赊销款的金额   liangby@2016-12-19
		$pay_method_info{pingzheng}=$in{"pingzheng".$pp};		##凭证号
		push(@pay_method,\%pay_method_info);
		if ($pay_method_info{Pay_Recv_total}<0 && $pay_method_info{pay_method} eq "1003.02.25.01" ) {
			print MessageBox("错误提示","对不起，火车票模块暂不支持退票款退到赊销款"); 
			exit;
		}
	}
	##判断重复凭证号,为了赊销款判断余额，需限制同一批次同一科目凭证号必须唯一   liangby@2015-6-11
	my @tradeno_check=();
	for (my $p=0;$p<$in{pay_method_num} ;$p++) {##多种付款科目	fanzy@2015-04-17
		if ($pay_method[$p]{pingzheng} ne "") {
			push(@tradeno_check,$pay_method[$p]{pay_method}."&,".$pay_method[$p]{Pay_type2}."&,".$pay_method[$p]{pingzheng});
		}
	}
	%count=();
	@tradeno_check=grep { ++$count{ $_ } >1; } @tradeno_check;
	if (scalar(@tradeno_check)>0) {
		my $error_msg;
		foreach my $tt (@tradeno_check) {
			my ($pay_kemu,$pay_bank,$pingzheng)=split/&,/,$tt;
			my $c_kemu_name=$kemu_hash{$pay_kemu}[0];
			my $c_bank_name=$kemu_hash{$pay_bank}[0];
			if ($error_msg ne "") {
				$error_msg .=",";
			}
			if ($c_kemu_name ne "") {
				$error_msg .="科目:$c_kemu_name";
			}else{
				$error_msg .="科目:$pay_kemu";
			}
			if ($c_bank_name ne "") {
				$error_msg .=",核算科目:$c_bank_name";
			}elsif($pay_bank ne ""){
				$error_msg .=",核算科目:$pay_bank";
			}
			$error_msg .="存在相同凭证号$pingzheng";
		}
		$error_msg .=",同一批次收银里同一科目凭证号必须唯一";
		
		print MessageBox("错误提示","对不起，$error_msg"); 
		exit;
	}
	$sql = "";
	my $is_ok=0;
	my @bkcorp_arr=();
	my @sql_array=();
	($paykemu_tp,$pay_bank_tp,$payment_rmk_tp,$trade_no_tp)=();   ##赊销款判断用
	my $last_method = $pay_method[0]{pay_method};
	$in{Comment}=~ s/\s*//g;
	$total_use=0;
	for ($i=0;$i<$in{t_num};$i++) {
		my	$cb="cb_$i";	my $res_id=$in{$cb};$res_id=~ s/\s*//g;
		if ($res_id ne "") {	## 选中的订单
			
			$is_ok=1;
			## ---------------------------------------------
			## 查询预订信息
			## ---------------------------------------------
			$sql_a="select b.User_type,b.Card_no,b.User_ID,a.Res_state,a.Total_price-a.Pay_amount,a.Total_price,
			a.Total_ticket_price,a.PP_method,a.Corp_ID
				from ctninfo..Train_book a,
					ctninfo..User_info b
				where a.User_ID=b.User_ID 
					and a.Reservation_ID='$res_id'
					and b.Corp_num='$Corp_center' ";
			$db->ct_execute($sql_a);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$user_type=$row[0];		$card_no=$row[1];	$user_id=$row[2];		
						$old_status=$row[3];	$left_total=$row[4];  $total_price=$row[5];
						$total_ticket_price=$row[6];	$old_pay=$row[7];	$bk_corp=$row[8];
					}
				}
			}
			push(@bkcorp_arr,$bk_corp);
			$user_type = &get_mcard_type($user_id);
			if ($old_status ne "S" && $old_status ne "H" &&$old_status ne "P") {	
				print MessageBox("错误提示","对不起，不能对订单$res_id进行收银操作！"); 
				exit;	
			}
			if ($old_pay eq 'N' && $total_price == 0) {
			}else{
				if ($left_total <= 0 && $total_price>=0) {
					print MessageBox("错误提示","对不起，订单$res_id已经进行过收银操作！"); 
					exit;	
				}
			}
			my $Comments;my $Trade_no;my %accumulative=();
			for (my $p=0;$p<$in{pay_method_num} ;$p++) {
				$sql_upt="";
				my $p_sh_recv=sprintf("%.2f",$pay_method[$p]{Pay_Recv_total_copy});  ##赊销款用到   liangby@2015-7-8
				if ($pay_method[$p]{Pay_Recv_total} == 0 || $in{"recv_".$i} == 0) {
					next;
				}
				my $r_price_total = $in{"recv_".$i};
				my $tag=$p;
				#print "<pre>第 $p 次 \n $pay_method[$p]{pay_method}|支付方式：$pay_method[$p]{Pay_Recv_total}|实收：$r_price_total</pre>";
				if ($pay_method[$p]{Pay_Recv_total}-$in{"recv_".$i}<0) {
					#$tag++;
					#if (!exists $pay_method[$tag]{pay_method}) {
					#	$tag--;
					#}
				}
				#print "<pre>剩余未收：".$in{"recv_".$i}."|支付方式：$pay_method[$p]{Pay_Recv_total}|实收：$r_price_total</pre>";
				$pay_method[$tag]{ReferNo}=~ s/\s*//g;
				$pay_method[$tag]{ReOp_date}=~ s/\s*//g;$pay_method[$tag]{ReOp_date}=~ s/\|//g;
				$pay_method[$tag]{BankName}=~ s/\s*//g;$pay_method[$tag]{BankName}=~ s/\|//g;
				$pay_method[$tag]{BankCardNo}=~ s/\s*//g;$pay_method[$tag]{BankCardNo}=~ s/\|//g;
				if ($pay_method[$tag]{pay_method} eq "1003.01.01" || $pay_method[$tag]{pay_method} eq "1003.01.02") {#POS收银保留银行卡号等
					$Trade_no=$pay_method[$tag]{ReOp_date}."|".$pay_method[$tag]{BankName}."|".$pay_method[$tag]{BankCardNo};
					$Comments=" 交易参考号:$pay_method[$tag]{ReferNo};交易日期:$pay_method[$tag]{ReOp_date};发卡行:$pay_method[$tag]{BankName};卡号后4位:$pay_method[$tag]{BankCardNo}";
				}else{
					$Trade_no=$pay_method[$tag]{pingzheng};
					$Comments=$pay_method[$tag]{pingzheng};
				}
				my $pay_total=0;
				##获取每张票的数据
				$sql_t=" select Seat_price,Window_price,Other_fee,Res_serial,Serial_no,isnull(Ins_price,0),Recv_price from ctninfo..Train_book_link where Reservation_ID='$res_id' ";
				$db->ct_execute($sql_t);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							my $serial = "$row[3]-$row[4]";
							my $left_price = $row[0]+$row[1]+$row[2]+$row[5]-$accumulative{$serial}-$row[6];
#							if ($in{User_ID} eq "admin") {
#								print "<Pre>$res_id,serial:$serial,left_price:$left_price,Pay_Recv_total:$pay_method[$p]{Pay_Recv_total},$row[0]+$row[1]+$row[2]+$row[5]-$accumulative{$serial}-$row[6]\n<br>";
#							}
							if ($pay_method[$p]{Pay_Recv_total} >= $left_price) {
								$r_price = $left_price;
							}else{
								$r_price = $pay_method[$p]{Pay_Recv_total};
							}
							if ($r_price >= $in{"recv_".$i}) {
								$r_price = $in{"recv_".$i};
							}
							if ($r_price <= 0) {
								next;
							}
							$in{"recv_".$i} -= $r_price;
							$pay_method[$p]{Pay_Recv_total} -= $r_price;
							$Left_total = $left_price - $r_price;
							#print "<br>总的应收：".$in{"recv_".$i}." 应收：$left_price 实收：$r_price 未收：$Left_total 本次用于支付的支付方式：$pay_method[$p]{pay_method}，剩余：$pay_method[$p]{Pay_Recv_total}";
							$pay_total+=$r_price;
							$sql_upt .=" update ctninfo..Train_book_link set Recv_price=Recv_price+$r_price,Pay_time=getdate(),Pay_method='$pay_method[$tag]{pay_method}'
								where Reservation_ID='$res_id' and Res_serial=$row[3] and Serial_no=$row[4] \n ";
							$sql_upt .=" if exists(select * from ctninfo..Train_book_pay where Reservation_ID='$res_id' and Res_serial=$row[3] and Seat_no=$row[4] )
								 begin
									 update ctninfo..Train_book_pay set Left_total=0 where Reservation_ID='$res_id' and Seat_no=$row[4] and (datediff(day,Pay_time,getdate()))=0 
									 insert into ctninfo..Train_book_pay(Reservation_ID,Res_serial,Seat_no,P_serial,Pay_object,Price_total,Recv_total,Left_total,User_ID,Corp_ID,Sales_ID,Comment,Pay_time,Op_type,Pay_bank,Trade_no,CID_corp)
									   select '$res_id',$row[3],$row[4],max(P_serial)+1,'$pay_method[$tag]{pay_method}',$left_price,$r_price,$Left_total,'$in{User_ID}','$Corp_ID','$Corp_center','批量收银$Comments备注：$in{Comment}',getdate(),'H','$pay_method[$tag]{Pay_type2}','$Trade_no','$bk_corp'
									 from ctninfo..Train_book_pay where Reservation_ID='$res_id' and Res_serial=$row[3] and Seat_no=$row[4]
								 end
								 else
								 begin
									 insert into ctninfo..Train_book_pay(Reservation_ID,Res_serial,Seat_no,P_serial,Pay_object,Price_total,Recv_total,Left_total,User_ID,Corp_ID,Sales_ID,Comment,Pay_time,Op_type,Pay_bank,Trade_no,CID_corp)
									   values('$res_id',$row[3],$row[4],0,'$pay_method[$tag]{pay_method}',$left_price,$r_price,$Left_total,'$in{User_ID}','$Corp_ID','$Corp_center','批量收银$Comments备注：$in{Comment}',getdate(),'H','$pay_method[$tag]{Pay_type2}','$Trade_no','$bk_corp')
								 end \n";
							$total_use +=$r_price;
							$sql_upt .=" update ctninfo..Train_book set Pay_amount=Pay_amount+$r_price,Pay_date=getdate() where Reservation_ID='$res_id' \n";
							$accumulative{$serial} += $r_price;
						}
					}
					
				}
				## 赊销款收银	fanzy@2017.05.19
				my $pay_kemu=$pay_method[$tag]{pay_method};
				my $pay_bank=$pay_method[$tag]{Pay_type2};
				my $pingzheng=$pay_method[$tag]{pingzheng};
				my $sxk_id=$pay_kemu.$pay_bank.$pingzheng;
				my $sql_sxk="";
				if ($p_sh_recv>0) {
					if ($bk_corp ne $Corp_center && $is_used{$sxk_id} eq "") {##赊销款结算
						$is_used{$sxk_id}="Y"; ##用于批量收银轧差判断，一个科目+核算项目+凭证号的赊销款只保存一条记录
						my $rt_result=&use_credit_payment($bk_corp,$pay_kemu,$pay_bank,$pingzheng,$p_sh_recv,$res_id,$kemu_hash{$pay_kemu}[0],$kemu_hash{$pay_bank}[0],$p_sh_recv,"火车票批量收银,订单$res_id金额$pay_total","0","Y");
						if ($rt_result=~/<error>/) {
							$rt_result=~ s/<error>//g;
							$rt_result=~ s/<\/error>//g;
							&write_log_trainpay("火车票批量收银:$res_id:$rt_result");
							print MessageBox("错误提示","对不起，$rt_result"); 
							exit;
						}else{
							$sql_sxk .=$rt_result;
							my $payment_str;
							if ($rt_result=~/Corp_credit_payment/) {
								$payment_str="[使用赊销款结算]";
								$paykemu_tp=$pay_kemu;
								$pay_bank_tp=$pay_bank;
								$trade_no_tp=$pingzheng;
								$payment_rmk_tp{$sxk_id}=$payment_str.",和订单$res_id同批收银";
								$sql_sxk .= "update ctninfo..Train_book_pay set Comment=str_replace(Comment,'$payment_str',null)+'$payment_str'+',赊销款扣款记录id:$bk_corp'+'_'+convert(varchar,\@s_no),Pay_status='SS'
									where Reservation_ID='$res_id' 
									   and Pay_object='$pay_kemu' and Pay_bank='$pay_bank' 
									   and CID_corp='$bk_corp' and Trade_no='$pingzheng' and Pay_time>=convert(char(10),getdate(),102) \n 
									delete from #tmp \n
									insert into #tmp(S_no) values(\@s_no) \n ";
							}
						}
					}elsif($bk_corp ne $Corp_center && $is_used{$sxk_id} eq "Y" && $payment_rmk_tp{$sxk_id} ne ""){
						$sql_sxk .=" declare \@s_no int \n
						   select top 1  \@s_no=S_no from #tmp \n";
						$sql_sxk .= "update ctninfo..Train_book_pay set Comment=str_replace(Comment,'$payment_rmk_tp{$sxk_id}',null)+'$payment_rmk_tp{$sxk_id}'+',赊销款扣款记录id:$bk_corp'+'_'+convert(varchar,\@s_no),Pay_status='SS'
									where Reservation_ID='$res_id' 
									   and Pay_object='$pay_kemu' and Pay_bank='$pay_bank' 
									   and CID_corp='$bk_corp' and Trade_no='$pingzheng' and Pay_time>=convert(char(10),getdate(),102) \n ";
						
						#if ($cp_sno{$sxk_id} ne "") {
							##更新赊销款扣款记录备注说明
							$sql_sxk .=" 
							   if \@s_no !=NULL 
								BEGIN
								update ctninfo..Corp_credit_payment set Remark=Remark+',其中$res_id金额$pay_total' where Sales_ID='$Corp_center' and Corp_ID='$bk_corp' and S_no=\@s_no and Op_type='1' 
								END \n";
						#}
					}
					$sql_upt .=$sql_sxk;
				}
				$last_method = $pay_method[$tag]{pay_method};
				$rmk_ms=5*$p+15; ##叠加时间
				$sql_upt .=" update ctninfo..Train_book set Res_state='H',PP_method='$last_method' where Reservation_ID='$res_id' \n";
				$sql_upt .= " insert into ctninfo..Train_Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) values('$res_id','F','$in{User_ID}','H',dateadd(ms,$rmk_ms,getdate())) \n ";
				if (grep {$_ eq $user_type} keys %m_type){	##收银完毕　　　　　　　liangby@2006-12-11
					##写入积分消费表，火车票积分为０
					$sql_upt .=&account_reward("$res_id","F","$Corp_center","$in{User_ID}","$user_id","$user_type","$last_method","火车票","$total_price");
				}
				push(@sql_array,$sql_upt);
			}
			
		}
	}
	if ($is_ok==0) {
		print MessageBox("错误提示","请选择订单后再批量收银!");
		exit;
	}
	#if ($in{User_ID} eq "admin") {
#		$test_sql="";
#		for(my $t=0;$t<scalar(@sql_array);$t++){
#			print "<pre>$t-> $sql_array[$t]</pre><br />";
#			$test_sql .=$sql_array[$t];
#		}
#		#print "<pre>$sql <br>2:=== $test_sql";
#		print MessageBox("错误提示","调试中...");
#		exit;
	#}
	#if ($sql=~/Corp_credit_payment/) {
		$tmp_top="create table #tmp(S_no Int NULL) \n";
		$tmp_tail="\n drop table #tmp \n";
	#}
	#@sql_array = grep { /\S/ } @sql_array;
	$sql = "$tmp_top begin transaction sql_insert \n";
	#print "<pre>$sql";
	#exit;
	my $Update = 0;
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_CMD_DONE) {
			next;
		}elsif($restype==CS_COMPUTE_RESULT) {
			next;
		}elsif($restype==CS_CMD_FAIL) {
			$Update = 0;		
			next;
		}elsif($restype==CS_CMD_SUCCEED) {
			$Update = 1;			
			next;
		}
		elsif($restype==CS_ROW_RESULT) {
			while(@row = $db->ct_fetch) {
			}
		}	
	 }

	if($Update eq '1') {
		if(scalar(@sql_array)>0){
			$Update=&write_array_to_db(\@sql_array,1);
		}
		else{
			$db->ct_execute("Commit Transaction sql_insert\n
			drop table #tmp \n");
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT) {
					while(@row=$db->ct_fetch) {
					}
				}
			}
		}
		if($total_use ne ""){

			$sc_msg =qq!<font style='color:blue;font-size:12px;'>成功收银$total_use</font>!;
		
		}
	}
	else{
		$db->ct_execute("Rollback Transaction sql_insert$tmp_tail");
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
				}
			}
		}
		
	}
	if ($Update==0) {
		$sql_upt="";
		for(my $t=0;$t<scalar(@sql_array);$t++){
			#print "<pre>$sql_array[$t]</pre><br />";
			$sql_upt .=$sql_array[$t];
		}
		&write_log_trainpay("火车票批量收银失败：".$sql_upt); #写日志 hejc@2018-01-09 
		print MessageBox("错误提示","收银操作数据写入失败,请联系系统管理员!");
		exit;
	}

}
### 获取客户信息　　　　　　　　　　　　　　　　liangby@2006-11-23
#$sql =" select a.Corp_ID,a.Corp_csname,a.Corp_type 
#       from ctninfo..Corp_info a 
#	   where  a.Corp_type in('S','T','A') 
#		 and a.Corp_status <> 'N' 
#		 and a.Corp_num='$Corp_center'";
#if ($Corp_type ne "T") {
#	$sql .=" and a.Corp_ID='$Corp_ID' ";
#}
#$sql .=" order by a.Corp_type desc";
#my $ticket_agent_list ="<option value=''>------ 全部客户 ------";
#$db->ct_execute($sql);
#while($db->ct_results($restype) == CS_SUCCEED) {						
#	if ($restype==CS_ROW_RESULT)	{
#		while(@row = $db->ct_fetch)	{
#			my $t_select;
#			if ($row[0] eq "$in{Corp_ID}" ) {
#				$t_select="selected";
#			}
#			if ($row[2] eq "T") {
#				$ticket_agent_list .="<option value=$row[0] style='background-color: #F9FCFF; color: red;' $t_select >【中心】　$row[1]";
#
#			}else{
#				$ticket_agent_list .="<option value=$row[0] style='background-color: #F9FCFF; color: magenta;' $t_select >【代理】　$row[1]";
#			}
#		}
#	}
#}

if ($in{Start} eq "") {
	$Start=1;
}else{
	$Start=$in{Start};
}
if ($in{Op} eq "") {	$in{Op} =0;	}
$op=$in{Op};
if ($in{Date_type} eq "") {
	if ($op == 0) {## 未收银
		$in{Date_type}="Ticket_date";
	}elsif ($op == 1) {## 已收银
		$in{Date_type}="Send_date";
	}elsif ($op == 2) {## 已收银 欠款
		$in{Date_type}="Send_date";
	}elsif ($op == 3) {## 已出票 未送
		$in{Date_type}="Ticket_date";
	}elsif ($op == 4) {## 已出票 未送
		$in{Date_type}="Reg_time";
	}else{
		$in{Date_type}="Ticket_date";
	}
}
if ($in{Date_type} eq "Ticket_date") {$date_type_p="selected";}
elsif ($in{Date_type} eq "Send_date") {$date_type_s="selected";}
elsif ($in{Date_type} eq "Reg_time") {$date_type_w="selected";}
if ($in{Depart_date} ne "") {	$Depart_date=$in{Depart_date};	}	else {	$Depart_date = $year.".".$month."."."$day";	}
$nextdate=&Nextdate($Depart_date);
$prevdate=&Prevdate($Depart_date);
if ($in{End_date} eq "") {	$in{End_date} = $nextdate;	}
$End_date = $in{End_date};
print qq!
<link rel="stylesheet" type="text/css" href="/admin/style/style.css" />
<link rel="stylesheet" type="text/css" href="/admin/style/tablelist.css" />
<style>
input{
	border: #B5B5B5 solid 1px;
}
</style>!;
my $href="/cgishell/golden/admin/airline/res/air_account.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}";
print qq!<div class="wrapper" id="setting_customer" >
	<div class="tabNav" id="parameter_tabs">
		<ul>
			<li$i_bg><a href="$href&Order_type=1"><img src="/admin/index/images/plane1.gif" />机　票</a></li>
			<li$o_bg><a href="$href&Order_type=2"><img src="/admin/index/images/person.gif" />其它产品</a></li>
			<li$t_bg><a href="/cgishell/golden/admin/hotel/res/hotel_account.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}"><img src="/admin/index/images/hotel.gif" />酒　店</a></li>
			<li class='current' ><a href="/cgishell/golden/admin/train/train_pay.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}"><img src="/admin/index/images/train.gif" />火车票</a></li>			
		</ul>
	</div>
</div>\n!;
print qq!
<center>
<SCRIPT language="JavaScript" src="/admin/js/date/js/date1.js"></SCRIPT>
<script type="text/javascript" src="/admin/js/ajax/jquery-1.3.2.min.js" charset="gb2312"></script>
<IFRAME id=CalFrame style="DISPLAY: none; Z-INDEX: 100; WIDTH: 148px; POSITION: absolute; HEIGHT: 194px" marginWidth=0 marginHeight=0 src="/admin/js/date/calendar.htm" frameBorder=0 noResize scrolling=no></IFRAME>
<form action='' method=get name=query>
<table border=0 cellpadding=0 cellspacing=0 width=100%>
	<tr><td height=20><font style='line-height:12pt;'>
		<font color=maroon><b>财务收银：</b></font>!;
		@op_name = ('未收银','已收银','已收银 欠款','已出票 未送','已确认 未出票');	## 代理费核算	 	返佣核算
		for ($i=0;$i<scalar(@op_name);$i++) {
			if ($op_name[$i] ne "") {
				print qq!<a href='Train_pay.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Op=$i&Corp_ID=$in{Corp_ID}&Start=1&Depart_date=$Depart_date&End_date=$End_date&Sender=$in{Sender}'>!;
				if ($in{Op} == $i) {
					print "<font color=red>$op_name[$i]</font></a> | ";
				}
				else{
					print "<font color=blue>$op_name[$i]</font></a> | ";
				}
			}
		}
	print qq!
	</td>
	<td align=right><select name="Date_type"><option value='Ticket_date' $date_type_p>出票日期</option><option value='Send_date' $date_type_s>配送日期</option><option value='Reg_time' $date_type_w>预订日期</option></select>：
		<font style='font-size:11pt;'>
		<a href='Train_pay.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Depart_date=$prevdate&Op=$in{Op}&Corp_ID=$in{Corp_ID}&Start=1&Date_type=$in{Date_type}' title='往前一天'><font face=webdings>7</font></a>
		<input type=text name=Depart_date class=grayline id=sdate size=10 maxlength=10 value='$Depart_date' onclick="event.cancelBubble=true;ShowCalendar(document.query.sdate,document.query.sdate,null,0,330)">
		 - <input type=text name=End_date class=grayline id=edate size=10 maxlength=10 value='$in{End_date}' onclick="event.cancelBubble=true;ShowCalendar(document.query.edate,document.query.edate,null,0,330)">
		<a href='Train_pay.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Depart_date=$nextdate&Op=$in{Op}&Corp_ID=$in{Corp_ID}&Start=1&Date_type=$in{Date_type}' title='往后一天'><font face=webdings>8</font></a>
		<input type=submit value=' 查询 '>
		<input type=hidden name=Op value='$op'>
		<input type=hidden name=User_ID value='$in{User_ID}'>
		<input type=hidden name=Serial_no value='$in{Serial_no}'>
	</td></tr>
	<tr><td height=1 bgcolor=808080 colspan=2></td></tr>
	<tr><td bgcolor=f0f0ff colspan=2>
		<table border=0 cellpadding=0 cellspacing=0 width=100%>
		<tr><td><font color=maroon><b>快速查询：</b></font>!;
		if ($Corp_type eq "T") {
			print qq!　客　户：!;
			&select_corp("","$in{Corp_ID}","style='width:90pt;'","Corp_ID","<option value=''>---- 全部客户 ---</option>");
		}
		if ($in{Pay_method} eq "C") {	$ck_c="selected";	}
		elsif ($in{Pay_method} eq "T") {	$ck_t="selected";	}
		elsif ($in{Pay_method} eq "N") {	$ck_n="selected";	}
		else {	$ck_a="selected";	}
		print qq!　订单号：<input type=text size=16 maxlength=16  name=Res_ID value='$in{Res_ID}' >
		姓名：<input type=text size=12 maxlength=16 name=Guest_name value='$in{Guest_name}'>
		结算：<select name=Pay_method><option value='' $ck_a>全部<option value='C' $ck_c>现付<option value='T' $ck_t>月结<option value='N' $ck_n>网上支付</select>
		</td></tr>
		<tr><td height=25>　　　　　　 送票员：<select name=Sender style='width:90pt;'>$s_list</select>　　　
		</td></tr></table>
	</td></tr>
</form>
<tr><td colspan=2>$sc_msg</td></tr>
<tr><td valign=top colspan=2>!;
## -------------------------------------------------------------------------
## 订单列表                 liangby@2006-11-28
## -------------------------------------------------------------------------
print "<table border=0 cellpadding=0 cellspacing=1  width=100% >";
print "<form action='train_pay.pl' method=post name=book>";
#<td>数量</td><td>退数</td>
$Header=qq!<table border=0 cellpadding=0 cellspacing=0 width=100%  background='/admin/images/table_line.gif'>
	<tr align=center height=20>!;
if ($op == 0 || $op == 2){	$Header .= "<td><font color=blue>批量</td>";	}
$Header .=qq!<td>出票机构</td><td>订单号</td><td>状态</td><td>结算方式</td>
	<td>送票员</td><td>日期</td><td>出发</td><td>抵达</td><td>车次</td><td>联系人</td><td style='cursor:pointer;' title="展开/收起所有乘机人"  onclick="expandAll();" data-set="Y">乘客</td><td>票面总价</td>
	<td>代售服务费</td><td>其他</td><td>保险</td><td>总金额</td><td>已收</td><td>退款</td>	<td>退票费</td><td>应收</td><td>实收</td></tr>!;
sub sum_account{
		local($type) = @_;
		my $cols_num = 1;
		if ($op == 0 || $op == 2){ $cols_num = 2; }
		if ($Find_res > 0) {
			$CTotal_num[$ii]=int($CTotal_num[$ii]);
			$CT_num[$ii]=int($CT_num[$ii]);
			$TTotal_num[$ii]=int($TTotal_num[$ii]);
			$TT_num[$ii]=int($TT_num[$ii]);
			print "<tr align=center>
			<td height=20 colspan=$cols_num></td>
			<td colspan=10 align=right>现付小计（订单 $CTotal_num[$ii] 张 车票 $CTkt_num[$ii] 张 退票 $CT_num[$ii] 张）：</td>";
			print "<td >$Cticket_price[$ii]</td><td>$Cwindow_price[$ii]</td><td>$COther_fee[$ii]</td><td>$CIns_price[$ii]</td>
			<td>$CTotal_price[$ii] </td><td>$CRecv_price[$ii]</td><td><font color=red>$CT_price[$ii]</td>
				<td><font color=red>$CBounce_price[$ii]</td><td>$CM_price[$ii]</td></tr>";
			print "<tr align=center>
			<td height=20 colspan=$cols_num></td>
			<td colspan=10 align=right>月结小计（订单 $TTotal_num[$ii] 张 车票 $TTkt_num[$ii] 张 退票 $TT_num[$ii] 张）：</td>";
			print "<td>$Tticket_price[$ii]</td><td>$Twindow_price[$ii]</td><td>$TOther_fee[$ii]</td><td>$TIns_price[$ii]</td>
			<td>$TTotal_price[$ii] </td><td>$TRecv_price[$ii]</td><td><font color=red>$TT_price[$ii]</td>
				<td><font color=red>$TBounce_price[$ii]</td><td>$TM_price[$ii]</td></tr>";
        }
		$TTotal_num=int($TTotal_num);
        $TT__num=int($TT__num);
		if ($type eq "Y") {
			if ($Find_res > 0) {
				print "<tr align=center><td height=20 colspan=$cols_num></td>
				<td colspan=10 align=right ><b>总计（订单 $TTotal_num 张 车票 $TTkt_num 张 退票 $TT_num 张）：</td>";
				 print "<td>$Tticket_price</td><td>$Twindow_price</td><td>$TOther_fee</td><td>$TIns_price</td>
						<td>$TTotal_price </td><td>$TRecv_price</td><td><font color=red>$TT_price</td>
					    <td><font color=red>$TBounce_price</td><td>$TM_price</td></tr>";
			}
		}
		print "</table>";
}

				  
				
$where = "	from ctninfo..Train_book a,
			 ctninfo..Train_book_line b,
			  ctninfo..Train_book_link e,
			 ctninfo..Corp_info c,
			 ctninfo..Corp_info d 
		where a.Reservation_ID=b.Reservation_ID
		and b.Reservation_ID=e.Reservation_ID
		and a.Reservation_ID=e.Reservation_ID
		and b.Res_serial=e.Res_serial
		and b.Res_serial=0
		and e.Res_serial=0
		and a.Corp_ID=c.Corp_ID 
		and a.Ticketagent_id=d.Corp_ID
		and a.Sales_ID='$Corp_center' 
		and c.Corp_num='$Corp_center'
		and d.Corp_num='$Corp_center' \n";

if($Corp_type eq "T" || ($Corp_type eq "A" && $Is_delivery eq "Y")){		##暂放开权限 中心或营业部可查询全部订单	linjw@2018-04-17
}else{
#if ($Corp_type ne "T" ) {##代理           lianby@2006-11-22
#	$where .= "and ((a.Corp_ID = '$Corp_ID' and c.Corp_ID= '$Corp_ID') 
#		or (a.Ticketagent_id='$Corp_ID' and d.Corp_ID='$Corp_ID')) \n";
	##只显示出票机构为$Corp_ID的订单
	$where .= "and a.Ticketagent_id='$Corp_ID' and d.Corp_ID='$Corp_ID' \n";
}
if ($in{Guest_name} ne "") { 
	$where .= " and upper(a.Contact) like upper('%$in{Guest_name}%') \n";	
}else{
	if ($in{Res_ID} ne "") {

		$where .=" and a.Reservation_ID='$in{Res_ID}' 
		      and a.Res_state in ('H','S','P') \n";
		##用订单号查询这个限制没必要了   liangby@2013-4-7
		#and datediff(day,b.Depart_date,getdate()) <= 60   
	}else{
		if ($in{Corp_ID} ne "") {	$where .= "and c.Corp_ID='$in{Corp_ID}' ";	}
		if ($in{Sender} ne "") {	
			if ($in{Sender} eq "%") {	
				$where .= "and a.Sender_ID='' ";	
			}
			else{
				$where .= "and a.Sender_ID='$in{Sender}' ";	
			}
		}
        if ($in{Pay_method} ne "") {	$where .= "and a.Pay_method='$in{Pay_method}' ";	}
		## 已配送 未收银
		if ($op == 0) {		
			$where .= "and a.Res_state in ('P','S')
			and a.Pay_amount=0 and a.PP_method='N' \n";
		}
		## 已收银
		elsif ($op == 1) {		
			$where .= "and a.Res_state = 'H'
			and a.Pay_amount = a.Total_price \n";
		}	
		## 已收银 欠款
		elsif ($op == 2) {	
			$where .= "and a.Res_state = 'H'
			and a.Pay_amount < a.Total_price \n";
		}
		#	and g.Recv_price < g.Origin_price + g.Tax_fee + g.YQ_fee ";	}
		## 已出票 未送
		elsif ($op == 3) {		
			$where .= "and a.Res_state= 'P' \n";
		}
		## 已出票 未送
		elsif ($op == 4) {		
			$where .= "and a.Res_state= 'Y' \n";
		}
		else{
			print "<div align=left><br><font color=red>提示：对不起，暂时不支持该操作！</div></td></tr></table>";
			exit;
		}
		if ($in{Date_type} eq "Ticket_date") {
			$where.="
			and a.Ticket_date >= '$Depart_date'
			and a.Ticket_date < '$End_date' \n";
		}
		elsif ($in{Date_type} eq "Send_date") {
			$where.="
			and a.Send_date >= '$Depart_date'
			and a.Send_date < '$End_date' \n";
		}
		elsif ($in{Date_type} eq "Reg_time") {
			$where.="
			and a.Reg_time >= '$Depart_date'
			and a.Reg_time < '$End_date' \n";
		}
	}

}
$where .= " order by a.Corp_ID,a.Reservation_ID ";
my $corp_id_t;
$Find_res = 0;	  $TTkt_num=0; 
$TTotal_num=0;    $TT_num=0;
$Tticket_price=0; $Twindow_price=0;
$TOther_fee=0;    $TTotal_price=0;    
$TRecv_price=0;   $TT_price=0; 
$TBounce_price=0; $TM_price=0;
$TIns_price=0;
$ii=0;	$i=0;
my $fake_resid; ## 只输出订单一行数据 jf on 2018/6/7
my $recv_input_onblur = "";
my %res_corpids=();
#+a.Total_bounce  应收统一算法，不再加退款，以后火车票退票需产生退票单  liangby@2018-4-17
$sql =" select a.Reservation_ID,a.Corp_ID,c.Corp_csname,a.User_ID,a.Ticketagent_id,d.Corp_csname,a.Res_state,a.Pay_method,
       convert(char(10),a.Send_date,102),b.Depart_city,b.Arrive_city,b.Train_order,a.Contact,a.Total_num,a.Pay_amount,
	   a.Total_price,a.Delivery_method,a.Total_bounce,a.T_num,a.Total_price-a.Pay_amount,a.Total_ticket_price,
	   a.Window_price,a.Other_fee,a.Bounce_price,a.Tkt_from,a.Is_account,a.Sender_ID,isnull(a.Ins_price,0),e.First_name,e.Serial_no ";
$sql .=$where ;
#print "<pre>$sql";

#exit;
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if ($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			  my $corp_name;
			  $row[0]=~s/\s*//g;
			  if ($corp_id_t ne $row[1]) {
					$res_corpids{$row[1]}=$row[1];
				  if($corp_id_t ne "" ){	## 显示旧客户的总计数据
					   &sum_account();
					}
				    $corp_id_t=$row[1];
				    $corp_name=$row[2];
					$ii++;
					$CTotal_num[$ii]=0;		$CT_num[$ii]=0;	         $Cticket_price[$ii]=0;    $Cwindow_price[$ii]=0;
					$COther_fee[$ii]=0;     $CTotal_price[$ii]=0;    $CRecv_price[$ii]=0;      $CT_price[$ii]=0; 
					$CBounce_price[$ii]=0;  $CM_price[$ii]=0;        $CTkt_num[$ii]=0;		   $CIns_price[$ii]=0;
					$TTkt_num[$ii]=0;		$TTotal_num[$ii]=0;		$TT_num[$ii]=0;	         $Tticket_price[$ii]=0;
					$Twindow_price[$ii]=0;	$TOther_fee[$ii]=0;     $TTotal_price[$ii]=0;    $TRecv_price[$ii]=0;
					$TT_price[$ii]=0;		$TBounce_price[$ii]=0;  $TM_price[$ii]=0;        $TIns_price[$ii]=0;

				    print qq!<table border=0 cellpadding=2 cellspacing=0 width=100%>
						<tr><td height=1 bgcolor=808080></td></tr>
						<tr bgcolor=f0f0f0><td height=23><b>客户名称：$corp_name ($corp_id_t)</td></tr>
						<tr><td height=1 bgcolor=808080></td></tr></table>!;
					    print $Header;
					                           
			 }
			 if($fake_resid ne $row[0]){
				 $fake_resid=$row[0];
				 my $p_method;
				 if ($row[7] eq "N") {
					$p_method="网上支付";
				 }elsif ($row[7] eq "C") {
					$p_method="现付"; 
					$CTkt_num[$ii]=$CTkt_num[$ii]+$row[13];
					$CTotal_num[$ii]=$CTotal_num[$ii]+1;		$CT_num[$ii]=$CT_num[$ii]+$row[18];	
					$Cticket_price[$ii]=$Cticket_price[$ii]+$row[20];    $Cwindow_price[$ii]=$Cwindow_price[$ii]+$row[21];
					$COther_fee[$ii]=$COther_fee[$ii]+$row[22];     $CTotal_price[$ii]=$CTotal_price[$ii]+$row[15];    
					$CRecv_price[$ii]=$CRecv_price[$ii]+$row[14];      $CT_price[$ii]=$CT_price[$ii]+$row[17]; 
					$CBounce_price[$ii]=$CBounce_price[$ii]+$row[23];  $CM_price[$ii]=$CM_price[$ii]+$row[19];
					$CIns_price[$ii]=$CIns_price[$ii]+$row[27];
				 }else{
					$p_method="月结";
					$TTkt_num[$ii]=$TTkt_num[$ii]+$row[13];
					$TTotal_num[$ii]=$TTotal_num[$ii]+1;		$TT_num[$ii]=$TT_num[$ii]+$row[18];	
					$Tticket_price[$ii]=$Tticket_price[$ii]+$row[20];    $Twindow_price[$ii]=$Twindow_price[$ii]+$row[21];
					$TOther_fee[$ii]=$TOther_fee[$ii]+$row[22];     $TTotal_price[$ii]=$TTotal_price[$ii]+$row[15];    
					$TRecv_price[$ii]=$TRecv_price[$ii]+$row[14];      $TT_price[$ii]=$TT_price[$ii]+$row[17]; 
					$TBounce_price[$ii]=$TBounce_price[$ii]+$row[23];  $TM_price[$ii]=$TM_price[$ii]+$row[19];
					$TIns_price[$ii]=$TIns_price[$ii]+$row[27];
				 }
				
				
				 my $b_status;
				if ($row[6] eq "W"){	$bstatus="新订单";	}			#新订单
				elsif ($row[6] eq "P"){	$b_status="出票";	}	        #出票
				elsif ($row[6] eq "S"){	$b_status="送票";	}		    #配送
				elsif ($row[6] eq "C"){	$b_status="取消";	}	        #取消
				elsif ($row[6] eq "H" && $row[14] == $row[15]){	$b_status="收银";   }	        #收银
				elsif ($row[6] eq "Y"){ $b_status="确认" }               #确认
				elsif ($row[6] eq "H" && $row[14]<$row[15]){ $b_status="欠款" }  #欠款
	#             my $card_no;
	#			 if($row[24] eq "C"||$row[24] eq "V") {## 会员
	#			    $card_no=$row[3];
	#             }else{
	#				 $card_no="<font color=blue>---";
	#			 }
				 my $tkt_from=$row[24];
				 my $account_str;
				 if ($tkt_from eq "2" || $tkt_from eq "3") {##外购票
					$account_str=qq!<a href="javascript:account('$row[0]')" title='外购结算' >!;
				 }
				
				 $sender=$user_name{$row[26]} ne ""? $user_name{$row[26]}:$row[26];
				 $depart_date=substr($row[8],5,9);
				 print qq!<tr align=center >!;
				 if ($op == 0 || $op == 2){	
					 print qq!<td height=20><input type=checkbox  name=cb_$i value='$row[0]' onclick="cal_recv();"></td>!;	
					 $recv_input_onblur = "cal_recv();";
				}
				 print qq!<td height=20><a href="javascript:pay('$row[0]')" title="财务收银" >$row[5]</a></td>
					  <td>$account_str $row[0]</td>
					  <td><font color=blue><a href="javascript:show_res('$row[0]');" title="查看订单">$b_status</a></font></td>
					  <td>$p_method</td>
					  <td>$sender</td>
					  <td>$depart_date</td>
					  <td>$row[9]</td>
					  <td>$row[10]</td>
					  <td>$row[11]</td>
					  <td>$row[12]</td>
					  <td class='js1_$row[0]' ><span onclick="fold_person(this,'$row[0]');" offinfo="N">$row[28]<sup id='num_$row[0]'></sup></span></td>
					  <td>$row[20]</td>
					  <td>$row[21]</td>
					  <td>$row[22]</td>
					  <td>$row[27]</td>
					  <td>$row[15]</td>
					  <td>$row[14]</td>
					  <td><font color=red>$row[17]</td>
					  <td><font color=red>$row[23]</td>
					  <td>$row[19]</td>
					  <td><input type=text name="recv_$i" value='$row[19]' onblur="$recv_input_onblur"></td>
					  </tr>!;
				print qq`<script>
					// 必须使用jQuery的ready函数,防止页面卡顿 jf on 2018/6/7 
					\$(function(){
						if(\$('.js1_'+'$row[0]').length > 1 ){
							\$('.js1_'+'$row[0]').eq(0).attr('title','展开/收起乘机人').end().eq(0).css({"cursor":"pointer"});
							\$('#num_'+'$row[0]').html("&nbsp;<span style='color:blue;font-size:13px;'>"+"共"+\$('.js1_'+'$row[0]').length+"位"+"</span>");
						}
					});
				 </script>`;
				$TTkt_num=$TTkt_num+$row[13];
				$TTotal_num=$TTotal_num+1;        $TT_num=$TT_num+$row[18]; 
				$Tticket_price=$Tticket_price+$row[20];  $Twindow_price=$Twindow_price+$row[21];
				$TOther_fee=$TOther_fee+$row[22];        $TTotal_price=$TTotal_price+$row[15];    
				$TRecv_price=$TRecv_price+$row[14];      $TT_price=$TT_price+$row[17]; 
				$TBounce_price=$TBounce_price+$row[23];  $TM_price=$TM_price+$row[19];
				$TIns_price=$TIns_price+$row[27];
				$i++;
				$Find_res++;
			 }else{
				## 这里输出多余的行
				 print qq!<tr align=center class='js_$row[0]' style='display:none;'>!;
				 if ($op == 0 || $op == 2){	
					 print qq!<td height=20 colspan=11>&nbsp;</td>!;		
				 }else{
					print qq!<td height=20 colspan=10>&nbsp;</td>!;
				 }
				 print qq`<td height=20 class='js1_$row[0]'>$row[28]</td>`;
				 print qq`<td height=20 colspan=10>&nbsp;</td>`;
			 }
			
		}
	}
}
&sum_account('Y');

if ($Find_res > 0){
	print qq~<script >
	function OpenWindow(theURL,winName,features) { 
		window.open(theURL,winName,features);
	}	
	function pay(r_id){
		OpenWindow('Train_pay_op.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Res_ID='+r_id,'_new',' resizable,scrollbars,width=800,height=600,status=yes');
	}
	function account(r_id){
		window.open('Train_account_op.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Res_ID='+r_id,'_new',' resizable,scrollbars,width=450,height=350,status=yes');
	}
	 function show_res(r_id){
	   OpenWindow('Train_book_view.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&ID='+r_id,'_new','resizable,scrollbars,width=800,height=400,toolbar=yes')
	}
	function Round(a_Num , a_Bit)  {
		  return( Math.round(a_Num * Math.pow (10 , a_Bit)) / Math.pow(10 , a_Bit))  ;
	}  
	function cal_recv(){
		var num=$i;
		var recv_total=0;
		var total = document.book.Ttotal.value;
		for (var j=0; j < num; j++){
			tmp=eval('document.book.cb_'+j);
			recv_price=eval("document.book.recv_"+j+".value;");
			if (tmp.checked) {
				recv_total = recv_total+parseFloat(recv_price);
			}			
		}
		document.book.Pay_Recv_total.value = Round(parseFloat(recv_total),2) ;
		document.book.Recv_total.value = Round(recv_total,2) ;
		document.book.Left_total.value = Round(total-recv_total,2) ;	
	}
	function ck_all(){	
		var num=$i;
		var i;
		for (i=0;i<num ;i++) {
			var tt
			tt=eval('document.book.cb_'+i);
			tt.checked = document.book.cb.checked;
		}
		cal_recv();
	}
	function amountcomp(){
		if ( document.book.t_num.value == 0 ) return;
		if(isNaN(document.book.Recv_total.value)){ 
			alert('金额必须是数字！') 
			document.book.Recv_total.focus(); 
			return false; 
		}
		
		var num=$i;
		for (var j=0; j < num; j++){
			tmp=eval('document.book.cb_'+j);
			recv_price=eval("document.book.recv_"+j+".value;");
			if (tmp.checked && recv_price == 0) {
				var Recv_msg = confirm("订单："+tmp.value+"实收金额为0，是否确定收银?")
				if (Recv_msg==true){
					
				}
				else{
					return false;
				}
			}			
		}

		var Pay_Recv_total=0;
		var num=parseInt(document.getElementById('pay_method_num').value,10);
		for (var m=0;m<num ;m++) {
			met_num='_'+m;
			if (m==0) {
				met_num='';
			}
			var pingzheng=document.getElementById("pingzheng"+met_num);
			var pingzhenglist=document.getElementById("pingzhenglist"+met_num);
			var Pay_balance=0;
			for(var i=0;i <pingzhenglist.options.length;i++){
				if (pingzheng.value==pingzhenglist.options[i].text) {
					var arr=[];arr=pingzhenglist.options[i].value.split("#");
					Pay_balance=Round(arr[1],2);
					break;
				}
			}
			var Pay_Recv_total_p=eval("document.book.Pay_Recv_total"+met_num);
			if (Round(Pay_Recv_total_p.value,2)>Round(Pay_balance,2) && Pay_balance>0) {
				alert('使用赊销款收银时，实收金额不能大于赊销款余额！');
				Pay_Recv_total_p.focus();
				return false; 
			}
			Pay_Recv_total=Pay_Recv_total+Round(Pay_Recv_total_p.value,2);
		}
		Pay_Recv_total=Round(Pay_Recv_total,2);
		if (Pay_Recv_total!=document.book.Recv_total.value) {
			alert('支付方式的实收金额之和'+Pay_Recv_total+'不等于选中订单的总实收合计'+document.book.Recv_total.value+'！');
			document.getElementById('Pay_Recv_total').focus(); 
			return false; 
		}
		var conret=confirm("确定提交?");
		if (conret==false) {
			return;
		}
		document.book.submit();
	}
	</script>~;

	if ($op == 0 || $op == 2){
		if ($Pay_version eq "1") {
			## 会计科目数组
			@array_list = &get_kemu($Corp_center,"","array",1,"Y");
			
		}else{
			##原收款方式的信息  
			$sql = "select rtrim(Pay_method),Pay_name,Is_netpay,Is_show,Is_payed,Corp_ID,Pay_pic from ctninfo..d_paymethod 
				where  Corp_ID in ('SKYECH','$Corp_center') 
				order by Order_seq,Is_netpay ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT) {
					while(@row = $db->ct_fetch) {
						$pay_method_hash{$row[0]}[0]=$row[1]; ##名称
						$pay_method_hash{$row[0]}[1]=$row[2];
						if ($row[3] eq "Y" && $row[2] eq "N" && $row[4] eq "Y") {
							push(@array_list, {Corp_ID   => "$row[5]",
									Type_ID => "$row[0]",
									Type_name  => "$row[1]",
									Pic => "$row[6]",
									Pid => "$row[0]",
								});
						}
					}
				}
			}
		}
		## 付款科目列表
		my $ass_ids;
		for (my $i = 0; $i < scalar(@array_list); $i++) {
			if ($array_list[$i]{Type_ID} eq '4003.01.03' || $array_list[$i]{Type_ID} eq '4003.01.04') {
				next;
			}
			if ($array_list[$i]{Type_ID} eq $array_list[$i]{Pid}) {		$array_list[$i]{Pid} = '';	}
			my $listitem = qq`['$array_list[$i]{Corp_ID}', '$array_list[$i]{Type_ID}', '$array_list[$i]{Type_name}', '$array_list[$i]{Pid}','0']`;
			push(@tmp_array_list, $listitem);
			if ($array_list[$i]{Pid} ne "") {
				$ass_ids .= "','$array_list[$i]{Pid}";
			}
		}
		## 付款银行列表
		if ($ass_ids ne "" && $Pay_version == 1) {
			#my @bank=&get_kemu($Corp_center,"","array","1","Y","N","assist","","Y");	
			my @bank=&get_kemu($Corp_center,"","array","1","Y","N","assist");	
			for (my $i = 0; $i < scalar(@bank); $i++) {
				my $listitem = qq`['$bank[$i]{Corp_ID}', '$bank[$i]{Type_ID}', '$bank[$i]{Type_name}', '$bank[$i]{Parent}','1']`;
				push(@tmp_array_list, $listitem);
				$bank_name{$bank[$i]{Type_ID}}=$bank[$i]{Type_name};
			}
		}
		my $array_list = join(",\n", @tmp_array_list);
		if ($Pay_version eq "1") {
			$list1_oh_str=qq! onchange="changelist('list1', 'list2')"!;
		}
		#print "<tr><td height=10></td></tr>
		#<tr bgcolor=fffff0>
		#<td height=20 colspan=15>支付方式：<select name=Pay_type style=width:100px>$pay_list</select>
		#实收：<input type=text name=Recv_total readonly class=grayline style='color:blue' size=8 value=0>
		#<font color=red><b>未结算：<input type=hidden name=Ttotal value='$TM_price'>
		#<input type=text name=Left_total readonly class=grayline size=8 style='color:red' value='$TM_price'></td></tr>
		#<tr><td height=10></td></tr>";
		print qq`
		<tr>
			<td height=10>
				<input type=checkbox name=cb onclick='ck_all();'> 选择全部订单&nbsp;&nbsp;  
				选中实收：<input type=text name=Recv_total readonly class=grayline style='color:blue' size=8 value=0>
				<font color=red><b>未结算：</b></font><input type=hidden name=Ttotal value='$TM_price'>
				<input type=text name=Left_total readonly class=grayline size=8 style='color:red' value='$TM_price'>
			</td>
			<td align=right>
				<input type=button value=' 确定 ' name=btok onclick='amountcomp()'>  
				<input type=reset value=' 重选 '>
			</td>
		</tr>
		<tr><td height=10></td></tr>`;

		my $paymaxnum=30;#支付方式允许最多3种
		my $more_btn=qq!<td>
				<span id="More_pay_mod"><nobr>
					<input name="" type="button" class="btn32" value="添加方式" onclick="More_pay('add');"/>
					<input name="" type="button" class="btn32" value="减少方式" onclick="More_pay('del');"/></nobr>
				</span>
			</td><td></td>!;
		for (my $p=0;$p<$paymaxnum ;$p++) {
			my $display=($p==0)?"":"display:none;";
			my $pp=($p==0)?"":"_$p";
			if ($p>0) {	$more_btn="";		}
			print qq`
			<tr id="paymore$pp" style="$display">
				<td>
					<table border=0 width=100% cellspacing=0 cellpadding=1 border=0 bgcolor=efefef style="border-bottom-color:#ddd;border-bottom-width:1px;border-bottom-style:dashed;">
						<tr>
							<td height=20 width=640>
								<label>支付方式：<select id="list1$pp" name='pay_method$pp' class="input_txt_select input_txtgy" style='width:130pt;' onchange="if('$Pay_version'=='1'){changelist('list1', 'list2','$p');};load_credit_payment('$p');"></select></label>
								<label>凭证号：<input type=text value='' id='pingzheng$pp' name='pingzheng$pp' class="input_txt input_txt70" style='width:100px;position:relative;z-index:10;' onchange="tradeno_verifys('$pp');">
										<select id='pingzhenglist$pp' name='pingzhenglist$pp' class="input_txt_select input_txtgy" style="height:18px;position:absolute;margin-top:0px;margin-left:-110px;width:124px;z-index:2;" onchange="change_cmt('pingzhenglist$pp', 'pingzheng$pp','Pay_balance$pp')" onclick="if(this.options.length==1){change_cmt('pingzhenglist$pp', 'pingzheng$pp','Pay_balance$pp');}"></select>
								</label>
								<label id="mod_Pay_Recv_total$pp">&nbsp;&nbsp;实收：<input type=text id="Pay_Recv_total$pp" name="Pay_Recv_total$pp" class="input_txt input_txt70" style='color:blue;width:40pt;' value=0 $sxk_event></label>
								<label>余额：<span id="Pay_balance$pp"></span></label>
							</td>
							$more_btn
						</tr>
						<tr>
							<td height=20 colspan=2>
								<label id='list2_lb$pp'>核算项目：<select id="list2$pp" name='Pay_type2$pp' class="input_txt_select input_txtgy" style='width:130pt;' onchange="load_credit_payment('$p');"></select></label>
								<label id='list3$pp'>交易参考号：<input type="text" id="ReferNo$pp" name="ReferNo$pp" maxlength=16 class="input_txt input_txt70" value="">
									发卡行：<input type="text" id="BankName$pp" name="BankName$pp" maxlength=8 class="input_txt input_txt70" value="">
									交易日期：<input type=text id="ReOp_date$pp" name="ReOp_date$pp" class="input_txt input_txt70" readonly maxlength=10 value='' onclick="event.cancelBubble=true;ShowCalendar(document.book.ReOp_date$pp,document.book.ReOp_date$pp,null,0,330)">
									卡号后4位：<input type="text" id="BankCardNo$pp" name="BankCardNo$pp" class="input_txt input_txt70" maxlength=4 value="">
								</label>
							</td>
						</tr>
					</table>
				</td>
			</tr>`;
		}
		print qq`<table width="100%" border="0" cellspacing="0" cellpadding="0">
					<tbody>
						<tr>
							<td width="70" rowspan="2">备　　注：</td>
							<td rowspan="2"><textarea name="Comment" maxlength="128" cols="" rows="" class="input_txt " style=" width:50%;height:50px;"></textarea></td>
						</tr>
					</tbody>
				</table>`;

		print qq`
			<input type='hidden' name='pay_method_num' id='pay_method_num' value='1'/>
			<input type='hidden' name='pay_method_maxnum' id='pay_method_maxnum' value='$paymaxnum'/>`;

		print qq`<tr><td height=10></td></tr>
		<script type="text/javascript">
		var payhash=[];
		var datalist = [$array_list];
		//增减支付方式
		function More_pay(type){
			var maxnum=parseInt(document.getElementById('pay_method_maxnum').value,10);
			var num=parseInt(document.getElementById('pay_method_num').value,10);
			if (type=='add') {
				if (num>=maxnum) {
					return;
				}
				num++;
				document.getElementById('pay_method_num').value=num;
			}else if(type=='del'){
				if (num<=1) {
					return;
				}
				num--;
				document.getElementById('pay_method_num').value=num;
			}
			for (var p=0;p<maxnum ;p++) {
				var pp='_'+p;
				if (p=='0') {
					pp='';
				}
				var paymore=document.getElementById('paymore'+pp);
				if (p<num) {
					paymore.style.display = "";
				}else{
					paymore.style.display = "none";
				}
			}
			if (num==1) {
				document.book.Pay_Recv_total.value = document.book.Recv_total.value;
				if (typeof(load_ccp) == "function") {
					var ccp_total=load_ccp('getsum','');
					document.book.Pay_Recv_total.value=Round(Round(document.book.Pay_Recv_total.value,2)-Round(ccp_total,2),2);
				}
			}
			if (document.getElementById('sxk_credit')) {
				sxk_event();
			}
		}
		function createlist(list, pid,payid) {
			var ppayid='_'+payid;
			if (payid=='0') {
				ppayid='';
			}
			removeAll(list);
			if (list.id=='list2'+ppayid) {
				list.style.display ='';
				document.getElementById("list2_lb"+ppayid).style.display='';
			}
			var listnum = 0;
			var bank_gid = '';
			var exists_value = [];
			for (var i = 0; i < datalist.length; i++) {
				if (pid != '' && datalist[i][1] == pid) {
					bank_gid=datalist[i][3];
				}
				if (pid != '' && (datalist[i][4] != '1' || bank_gid != datalist[i][3])){
					continue;
				}
				if (pid == '' && datalist[i][4] != '0')	{	// 付款方式
					continue;
				}
				if (array_exists(exists_value, datalist[i][1]))	// 过滤重复的下拉列表
				{
					continue;
				}
				list[list.options.length] = new Option(datalist[i][2], datalist[i][1]);
				exists_value.push(datalist[i][1]);	// 写入数组变量内用于判断重复
				if ('$Corp_center' == datalist[i][0]) {
					list.options[listnum].style.color = '#0000FF';
				}
				for (var h=0;h<payhash.length ;h++) {
					if (datalist[i][4]=='0' && datalist[i][1]==payhash[h]["Pay_kemu"]) {
						list.options[listnum].style.color = 'red';
					}
					if (payhash[h]["Pay_bank"]==' ') {payhash[h]["Pay_bank"]='';}
					if (datalist[i][4]=='1' && datalist[i][1]==payhash[h]["Pay_bank"]) {
						list.options[listnum].style.color = 'red';
					}
				}
				listnum++;
			}
			if (listnum>0) {
				list.options.selectedIndex=0;
			}else{
				if (list.id=='list2'+ppayid) {
					list.style.display ='none';
					document.getElementById("list2_lb"+ppayid).style.display='none';
				}
			}
			if (pid=='1003.01.01' || pid=='1003.01.02') {//POS收银保留银行卡号等fanzy2012-6-27
				document.getElementById("list3"+ppayid).style.display='';
			}else {
				document.getElementById("list3"+ppayid).style.display='none';
			}
		}
		function changelist(src, obj,payid) {
			var ppayid='_'+payid;
			if (payid=='0') {
				ppayid='';
			}
			src = document.getElementById(src+ppayid);
			obj = document.getElementById(obj+ppayid);
			var srcvalue = '';
			if (src)
			{
				srcvalue = src.options[src.options.selectedIndex].value;
			}
			createlist(obj, srcvalue,payid);
		}
		var removeAll = function(obj)
		{
			obj.options.length = 0;
		}
		//检查数组元素是否存在
		function array_exists(arr, item)
		{
			for (var n = 0; n < arr.length; n++)
			if (item == arr[n]) return true;
			return false;
		}
		function change_cmt(selectobj, inputobj, inputobj1){
			var sIndex=document.getElementById(selectobj).selectedIndex;
			var prod = document.getElementById(selectobj).options[sIndex].text;
			var prods = document.getElementById(selectobj).options[sIndex].value;
			document.getElementById(inputobj).value = prod;
			var arr=[];arr=prods.split("#");
			document.getElementById(inputobj1).innerHTML = arr[1];
		}
		function load_credit_payment(payid) {
			if (payhash.length==0) {
				return;
			}
			var ppayid='_'+payid;
			if (payid=='0') {
				ppayid='';
			}
			var list1=document.getElementById("list1"+ppayid).value;
			var list2=document.getElementById("list2"+ppayid).value;
			var pingzheng=document.getElementById("pingzheng"+ppayid);
			var pingzhenglist=document.getElementById("pingzhenglist"+ppayid);
			var Pay_balance=document.getElementById("Pay_balance"+ppayid);
			pingzheng.value="";
			pingzhenglist.options.length = 0;
			Pay_balance.innerHTML="";
			for (var i=0;i<payhash.length ;i++) {
				if (payhash[i]["Pay_bank"]==' ') {payhash[i]["Pay_bank"]='';}
				if (list1==payhash[i]["Pay_kemu"] && list2==payhash[i]["Pay_bank"]) {
					pingzhenglist.options.add(new Option(payhash[i]["Trade_no"],payhash[i]["Trade_no"]+'#'+payhash[i]["Amount"]));
				}
			}
			if (pingzhenglist.options.length>0) {
				pingzhenglist.selectedIndex=0;
				change_cmt("pingzhenglist"+ppayid,"pingzheng"+ppayid,"Pay_balance"+ppayid);
			}
		}
		function tradeno_verifys(pp){
			var pingzheng=document.getElementById("pingzheng"+pp);
			var pingzhenglist=document.getElementById("pingzhenglist"+pp);
			document.getElementById('Pay_balance'+pp).innerHTML="";
			for(var i=0;i <pingzhenglist.options.length;i++){
				if (pingzheng.value==pingzhenglist.options[i].text) {
					pingzhenglist.options.selectedIndex = i;
					pingzhenglist.onchange();
					break;
				}
			}
		}
		for (var i=0;i<parseInt(document.getElementById("pay_method_maxnum").value,10) ;i++) {
			changelist('', 'list1',i);
			changelist("list1","list2",i);
		}
		</script>`;

		print "
		<input type=hidden name=Guest_name value='$in{Guest_name}'><input type=hidden name=PNR value='$in{PNR}'>
		<input type=hidden name=Corp_ID value='$in{Corp_ID}'><input type=hidden name=Sender value='$in{Sender}'>
		<input type=hidden name=Pay_method value='$in{Pay_method}'><input type=hidden name=Op value=$op>
		<input type=hidden name=Depart_date value='$Depart_date'><input type=hidden name=End_date value='$End_date'>
		<input type=hidden name=User_ID value='$in{User_ID}'><input type=hidden name=Serial_no value='$in{Serial_no}'>
		<input type=hidden name=sh_event value=0>
		<input type=hidden name=action value='W'>
		<input type=hidden name=t_num value=$i>
		<input type=hidden name=Date_type value='$in{Date_type}'>";
		
		$pay_ment_corp=$in{Corp_ID};
		if ($pay_ment_corp eq "") {
			@res_corpids=keys %res_corpids;
			if (scalar(@res_corpids)==1) {
				$pay_ment_corp=$res_corpids[0];
			}
		}
		if ($pay_ment_corp ne $Corp_center && $pay_ment_corp ne "") {##获取赊销款余额   fanzy@2017.05.18
			print qq`<tr><td colspan=2>
			#<script type="text/javascript" src="/admin/js/ajax/jquery-1.3.2.min.js" charset="gb2312"></script>
			<div class="wrapper" id="auto_process"></div>
				<div id="payment_show" style="background:#f4f4f4; border-top: #ff6600 solid 1px;width:550px;height:200px;overflow:auto;overflow-x:hidden;display:none;" ></div>
			</td></tr>`;
			print qq`<script language=javascript>
				function get_credit_payment(){
					document.getElementById('auto_process').innerHTML='正在获取赊销款信息！请稍候………';
					\$.ajax({type:"POST",dataType:'jsonp',timeout:'120000',url:"/cgishell/golden/admin/pub/json_corp_creidt_payment.pl?callback=?",
						data:{User_ID:'$in{User_ID}',Serial_no:'$in{Serial_no}',Agent_ID:'$pay_ment_corp'},
						success:function(data){
							if (data['status']=='OK') {
								document.getElementById('auto_process').innerHTML = '';
								if (data['payment'][0]) {
									var html_str="";
									for (var i=0;i<data['payment'].length;i++){
										var Pay_kemu=data['payment'][i]['Pay_kemu'];
										var kemu_name=data['payment'][i]['kemu_name'];
										var Pay_bank=data['payment'][i]['Pay_bank'];
										var bank_name=data['payment'][i]['bank_name'];
										var Trade_no=data['payment'][i]['Trade_no'];
										var Amount=data['payment'][i]['Amount'];
										html_str +="<tr><td>"+kemu_name+"</td><td>"+bank_name+"&nbsp;</td><td>"+Trade_no+"</td><td>"+Amount+"</td></tr>";

									}
									if (html_str !="") {
										html_str="<br /><table  border=1 bordercolor=808080 width=500 bordercolordark=FFFFFF cellpadding=0 cellspacing=0  ><tr><td colspan=4>客户(<b>$pay_ment_corp</b>)赊销款余额明细</td></tr><tr bgcolor=f2f2f2 height=30 ><td>付款科目</td><td>付款核算项目</td><td>凭证号</td><td>余额</td></tr>"+html_str+"</table>";
										document.getElementById("payment_show").style.display="";
									}
									document.getElementById('payment_show').innerHTML=html_str;
									payhash=data['payment'];
									if (document.getElementById('pay_method_maxnum')) {
										for (var p=0;p<parseInt(document.getElementById('pay_method_maxnum').value,10) ;p++) {
											changelist('', 'list1',p);
											changelist("list1","list2",p);
											load_credit_payment(p);
										}
									}
								}
								
							}
							else{
								document.getElementById('auto_process').innerHTML = '赊销款错误提示：'+data['message']+" <input type='button' id='ticketing_rest' value='重新查询赊销款' title='重新查询赊销款' class='btn30' onmouseover=\\"this.className='btn31'\\" onmouseout=\\"this.className='btn30'\\" onclick=\\"get_credit_payment();\\" />";
							}
						},
						error: function(XMLHttpRequest, textStatus, errorThrown){
							var textStatus_str=textStatus;
							if (textStatus=="timeout") {
								textStatus_str="网络超时,请稍后重试";
							}else if (textStatus=="error") {
								textStatus_str="后台服务程序出错";
							}
							document.getElementById('auto_process').innerHTML = '赊销款错误提示：'+textStatus_str+" <input type='button' id='ticketing_rest' value='重新查询赊销款' title='重新查询赊销款' class='btn30' onmouseover=\\"this.className='btn31'\\" onmouseout=\\"this.className='btn30'\\" onclick=\\"get_credit_payment();\\" />";;
							
							
						}
					});
					
				}
				get_credit_payment();
				</script>`;
		}
	}	
}
else{
	print "<tr><td height=20><font color=red>没有符合条件的数据";
}
print "</td></tr></table></form>";

print "</td></tr></table>";
print qq`<script>
	function fold_person(obj,id){
		if (obj.offinfo=="Y") {
			obj.offinfo="N";
			\$(".js_"+id).each(function(){
				\$(this).hide();
			});
			\$("#num_"+id).show();
		}else{
			obj.offinfo="Y";
			\$(".js_"+id).each(function(){
				\$(this).show();
			});
			\$("#num_"+id).hide();
		}
	}	
	function expandAll(){
		if(\$(this).attr('dataSet')=="N"){
			\$('span[offinfo]').each(function(){
				\$(this).attr({'offinfo':'Y'}).click();
			});
			\$(this).attr('dataSet','Y');
		}else{
			\$('span[offinfo]').each(function(){
				\$(this).attr({'offinfo':'N'}).click();
			});
			\$(this).attr('dataSet','N');
		}
	}
</script>`;
print "</body></html>";



sub write_log_trainpay{
	my ($s_msg)=@_;
	my ($today2,$today)=();
	$today2=$today = &cctime(time);
	($week,$month,$day,$time,$year)=split(" ",$today);
	if($day<10){$day="0".$day;}
	if($month<10 && length($month)==1){$month="0".$month;}
	$today=$year.".".$month."."."$day";
	my $file_date=$today;
	$file_date=~ s/\.//g;
	my $log_path="d:/logs/";
	if (! -e $log_path) {#目录不存在
		 mkdir($log_path,0002);
	}elsif(!-d $log_path){#存在文件但不是目录
		 mkdir($log_path,0002);
	}
	$log_path .="/lib/";
	if (! -e $log_path) {#目录不存在
		 mkdir($log_path,0002);
	}elsif(!-d $log_path){#存在文件但不是目录
		 mkdir($log_path,0002);
	}
	$filename=">> $log_path"."train_pay_$file_date.log";
	open MAIL,"$filename" || die "错误：不能打开文件";
	print MAIL "----------------------$today2" || die "error"; 
	print MAIL "$s_msg \n";
	close(MAIL);
}