#!c:/Perl/bin/Perl.exe
require "ctnlib/golden/common.pl";
require "ctnlib/golden/html.pl";
require "ctnlib/golden/datelib.pl";
require "ctnlib/golden/cgi-lib.pl";
require "ctnlib/golden/manage.pl";
require "ctnlib/golden/crypt_cbc.pl";

use Sybase::CTlib;
use Spreadsheet::WriteExcel::Big;
use MD5;
## =====================================================================
## start program
## ---------------------------------------------------------------------
## Read Post/Get Datas,use cgi-lib.pl
## ---------------------------------------------------------------------
&ReadParse();
## ---------------------------------------------------------------------
## Print Html header,use Html.pl
## ---------------------------------------------------------------------
if ($in{action} ne "Q"){
	&Header("三方协议管理");
}else{
	print "Pragma:no-cache\r\n";
	print "Cache-Control:no-cache\r\n";
	print "Expires:0\r\n";
	print "Content-type:text/html;charset=GB2312;\n\n";
}
## =====================================================================
$Corp_ID = ctn_auth("SFXY");
if(length($Corp_ID) == 1) { exit; }
foreach $arr (sort keys(%in)) {
	$in{$arr}=~ s/'/‘/g;
	$in{$arr}=~ s/"/“/g;
}
$in{air_code}=~tr/a-z/A-Z/;
## 得到用户及其公司类型	$Corp_type $User_type
&get_op_type();

if($in{new_temp} eq "Y" ){#销售统计详细 hecf 2015/1/5
	if ($in{date_type} eq "") {$in{date_type}="A";}
	my %hax = &Get_service_ip("J_REPORT_HX");
	my $server;
	if ($ENV{HTTP_HOST} ne "" && (substr($ENV{HTTP_HOST},0,3) eq "127" || substr($ENV{HTTP_HOST},0,3) eq "192" 
		|| substr($ENV{HTTP_HOST},0,3) eq "172")) {
		if($hax{"J_REPORT_HX"}{"inter_ip"} ne ""){
			if($hax{"J_REPORT_HX"}{"port"} ne ""){
				$server=$hax{"J_REPORT_HX"}{"inter_ip"}.":".$hax{"J_REPORT_HX"}{"port"};
			}else{
				$server=$hax{"J_REPORT_HX"}{"inter_ip"};
			}
		}else{
			$server=$J_SERVER;
		}
	}elsif($hax{"J_REPORT_HX"}{"ext_ip"} ne ""){
		if($hax{"J_REPORT_HX"}{"port"} ne ""){
			$server=$hax{"J_REPORT_HX"}{"ext_ip"}.":".$hax{"J_REPORT_HX"}{"port"};
		}else{
			$server=$hax{"J_REPORT_HX"}{"ext_ip"};
		}
	}else{
		$server=$J_SERVER;
	}
	my $czwheresql="";
	if ($in{date_type} eq "A") {
		$czwheresql .= " and Airbook_lines.Air_date >= '$in{cur_month}.01'
			and Airbook_lines.Air_date < dateadd(month,1,'$in{cur_month}.01') ";
	}else{
		$czwheresql .= " and Airbook.Ticket_time >= '$in{cur_month}.01'
			and Airbook.Ticket_time < dateadd(month,1,'$in{cur_month}.01') ";
	}
	if ($in{Air_type} ne "") {
		$czwheresql .= " and Airbook.Air_type='$in{Air_type}' ";
	}
	if($in{Tk_type} ne ""){
		$czwheresql .= " and Airbook_detail.Is_ET='$in{Tk_type}' ";
	}
	$czwheresql .= " and Airbook_lines.Airline_ID='$in{air_code}'
			and Airbook.Corp_ffp='$in{Corp_ffp}'
			and Airbook.Book_status<>'C' ";
	#if($in{debug_sql} eq 'Y'){
		#print $czwheresql;
		#exit;
	#}
	$czwheresql=&Encrypt($czwheresql);
	my $uri="http://$server/CustomReport/pages/bill/showSelect.htm?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&reportId=1000";
	print qq`
	<form action="$uri" method="post" name=new_detail2 target=ffp_detail method=post >
		<input type="hidden" name="czwheresql" value="$czwheresql"/>
	</form>
	<script type='text/javascript'>
		document.new_detail2.submit();
	</script>`;
}

$in{air_ffp}=~tr/a-z/A-Z/;
my $air_list;
if ($in{action} ne "") {
	if($in{action} eq "Q"){ ##查询已绑定的协议
		if ($in{air_code} eq "") {
		my $sql_t="select count(Air_ffp) from ctninfo..Ffp_card where Sales_ID = '$Corp_center' and Card_ID='$in{CardId}' and Airline_code ='$in{AirCode}'";
		$db->ct_execute($sql_t);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					 $be_bound = $row[0];
				}
			}
		}
		my $result = qq`$in{callback}({'be_bound':$be_bound});`;
		print $result;
		exit;
		}
	}
	$sql = qq!declare \@s_id integer
		BEGIN Transaction sql_insert \n!;
	if ($in{air_ffp} eq "") {
		print &showMessage("错误提示", "对不起，请输入三方协议号！", "goback", "", 2, "");
		&Footer();
		exit;
	}
	if ($in{Type} eq "A" && $in{action} eq "del"){
		my $is_exist="";
		$sql_t = " select a.Corp_ID from ctninfo..Corp_info a, ctninfo..Corp_ffp b
			where a.Corp_num='$Corp_center' and b.Sales_ID='$Corp_center' and a.Corp_ID=b.Corp_ID
				and b.Airline_code='$in{air_code}' and b.Air_ffp='$in{air_ffp}' and b.Tag_char in(null,'','C') \n";
		$db->ct_execute($sql_t);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$is_exist="对不起， 您要删除的 $in{air_code} 三方协议号 $in{air_ffp} 已经绑定了客户，请解除绑定后再删除！";
				}
			}
		}
		$sql_t2 = " select Air_ffp from ctninfo..Ffp_card
			where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' \n";
		$db->ct_execute($sql_t2);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$is_exist="对不起， 您要删除的 $in{air_code} 三方协议号 $in{air_ffp} 已经绑定了旅客信息，请删除旅客信息后再删除三方协议号！";
				}
			}
		}
		if ($is_exist ne "") {
			print &showMessage("错误提示", "$is_exist", "goback", "", 2, "");
			&Footer();
			exit;
		}
		$sql .= "delete from ctninfo..Ffp_info where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' \n";
		$sql .= "delete from ctninfo..Ffp_discount where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' \n";
		$sql .= "delete from ctninfo..Ffp_card where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' \n";
		$in{air_code}="";	$in{air_ffp}="";
	}
	elsif (($in{Type} eq "D" || $in{Type} eq "E") && $in{action} eq "add"){ ## 协议维护
		## 查询是否存在录入或修改的三方协议号
		#my $is_exist="";
		#$sql_t = "select Airline_code,Air_ffp from ctninfo..Ffp_info
			#where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' \n";
		#$db->ct_execute($sql_t);
		#while($db->ct_results($restype) == CS_SUCCEED) {
			#if($restype==CS_ROW_RESULT)	{
				#while(@row = $db->ct_fetch)	{
					#$is_exist="对不起，输入的 $in{air_code} 三方协议号 $in{air_ffp} 已存在，请重新输入！";
				#}
			#}
		#}
		#if ($is_exist ne "") {
			#print &showMessage("错误提示", "$is_exist", "goback", "", 2, "");
			#&Footer();
			#exit;
		#}
		$in{air_ffp} =~ tr/a-z/A-Z/;
		$in{office_id} =~ s/，/,/;
		if ($in{Start_date} ne "" && date_check($in{Start_date}) ne 1) {
			print &showMessage("错误提示", "对不起，开始日期错误！", "goback", "", 2, "");
			&Footer();
			exit;
		}
		if ($in{End_date} ne "" && date_check($in{End_date}) ne 1) {
			print &showMessage("错误提示", "对不起，结束日期错误！", "goback", "", 2, "");
			&Footer();
			exit;
		}
		if ($in{Start_date} ne "" && $in{End_date} eq "") {
			print &showMessage("错误提示", "对不起，请输入结束日期！", "goback", "", 2, "");
			&Footer();
			exit;
		}
		if ($in{Start_date} eq "" && $in{End_date} ne "") {
			print &showMessage("错误提示", "对不起，请输入开始日期！", "goback", "", 2, "");
			&Footer();
			exit;
		}

		$update_tag_int=",Tag_int=isnull(Tag_int,0)";
		$insert_tag_int="0";
		if ($in{Status}==1) {
			$s_tag_int.="|1";
		}
		else{
			$s_tag_int.="&(~1)";
		}
		if ($in{ffp_type}==1) {	##二方协议
			$s_tag_int.="|8";
		}
		else{	##三方协议
			$s_tag_int.="&(~8)";
		}
		if ($in{reward_way}==1) {	##前返
			$s_tag_int.="|2&(~4)";
		}
		elsif($in{reward_way}==2){	##后返
			$s_tag_int.="&(~2)|4";
		}
		elsif($in{reward_way}==3){	##前后返
			$s_tag_int.="|2|4";
		}
#		if ($in{auto_command} == 1){ ## sfc前自动做RMK IC指令
#			$s_tag_int.="|16";
#		}else{
#			$s_tag_int.="&(~16)";
#		}
		$insert_tag_int.=$s_tag_int;
		$update_tag_int.=$s_tag_int;
		if ($in{apply_attach} ne ""){
			my $ffp_url="http://$G_SERVER/";
			$in{apply_attach} =~ s/$ffp_url//;
		}

		if ($in{Start_date} eq "") {
			$in{Start_date}=qq!null!;
		}else{
			$in{Start_date}=qq!'$in{Start_date}'!;
		}
		if ($in{End_date} eq "") {
			$in{End_date}=qq!null!;
		}else{
			$in{End_date}=qq!'$in{End_date}'!;
		}
		if ($in{task_num} eq "") {	$in{task_num}="null";		}
		$in{sub_num}=sprintf("%.0f",$in{sub_num});
		if ($in{sub_num}==0) {
			print &showMessage("错误提示", "对不起，请添加始发城市！", "goback", "", 2, "");
			&Footer();
			exit;
		}
		$sql .= " delete from ctninfo..Ffp_info where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}'  and Sub_ID>=$in{sub_num} \n";
		$sql .= " delete from ctninfo..Ffp_discount where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' and Air_type='Y' and Sub_ID>=$in{sub_num} \n";
		$sql .= " delete from ctninfo..Ffp_discount where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' and Air_type='Y' and Corp_ID='$Corp_center'	\n";
		for (my $f=0;$f<$in{sub_num} ;$f++) {
			$depart_N{$f}=$in{"depart_N$f"};		$depart_N{$f}=~ s/，/,/;			$depart_N{$f}=~ tr/a-z/A-Z/;
			$depart_Y{$f}=$in{"depart_Y$f"};		$depart_Y{$f}=~ s/，/,/;			$depart_Y{$f}=~ tr/a-z/A-Z/;
			$arrive_N{$f}=$in{"arrive_N$f"};		$arrive_N{$f}=~ s/，/,/;			$arrive_N{$f}=~ tr/a-z/A-Z/;
			$arrive_Y{$f}=$in{"arrive_Y$f"};		$arrive_Y{$f}=~ s/，/,/;			$arrive_Y{$f}=~ tr/a-z/A-Z/;
			$class_N{$f}=$in{"class_N$f"};			$class_N{$f}=~ tr/a-z/A-Z/;
			$class_Y{$f}=$in{"class_Y$f"};			$class_Y{$f}=~ tr/a-z/A-Z/;
			$Comm_rate_N{$f}=$in{"Comm_rate_N$f"};	if ($Comm_rate_N{$f} eq "") {	$Comm_rate_N{$f}=0;		}
			##Comm_rate_N改成定额代理，取消原来的代理费点数，原字段Comm_rate废弃不用    liangby@2016-7-15
			$seatnum_N{$f}=$in{"seatnum_N$f"};	$seatnum_N{$f}=sprintf("%.0f",$seatnum_N{$f});
			$seatnum_Y{$f}=$in{"seatnum_Y$f"};	$seatnum_Y{$f}=sprintf("%.0f",$seatnum_Y{$f});
			$Ref_office=join(",",("$in{Ref_office1}","$in{Ref_office2}"));  ##搭桥Office　   liangby@2014-8-14
			$sql.=" if exists (select * from ctninfo..Ffp_info where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' and Sub_ID=$f)
				begin
					update ctninfo..Ffp_info set Task_num=$in{task_num},Office_ID='$in{office_id}',Depart_N='$depart_N{$f}',Arrive_N='$arrive_N{$f}',Class_N='$class_N{$f}',
						Depart_Y='$depart_Y{$f}',Arrive_Y='$arrive_Y{$f}',Class_Y='$class_Y{$f}',Comment='$in{comment}',User_ID='$in{User_ID}',Op_time=getdate(),
						Start_date=$in{Start_date},End_date=$in{End_date},Ref_office='$Ref_office',Comm_rate=0,Dis_rate=$Comm_rate_N{$f} $update_tag_int,Core_memo='$in{coreNote}',Info_memo='$in{infoNote}',File_name='$in{apply_attach}'
					where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' and Sub_ID=$f
				end
				else
				begin
					insert into ctninfo..Ffp_info(Sales_ID,Airline_code,Air_ffp,Office_ID,Task_num,Depart_N,Arrive_N,Class_N,
						Depart_Y,Arrive_Y,Class_Y,Comment,User_ID,Op_time,Start_date,End_date,Sub_ID,Ref_office,Comm_rate,Dis_rate,Tag_int,Core_memo,Info_memo,File_name)
					values ('$Corp_center','$in{air_code}','$in{air_ffp}','$in{office_id}',$in{task_num},'$depart_N{$f}','$arrive_N{$f}','$class_N{$f}',
						'$depart_Y{$f}','$arrive_Y{$f}','$class_Y{$f}','$in{comment}','$in{User_ID}',getdate(),$in{Start_date},$in{End_date},$f,'$Ref_office',0,$Comm_rate_N{$f},$insert_tag_int,'$in{coreNote}','$in{infoNote}','$in{apply_attach}')
				end \n";
			##增加折扣
			for (my $i=0;$i<$seatnum_N{$f};$i++) {
				my $class = "class_N_$i"."sub$f";
				my $dis = "dis_N_$i"."sub$f";
				my $agt = "agt_N_$i"."sub$f";
				if ($in{$dis} eq "") {
					print &showMessage("错误提示", "对不起，请输入舱位折扣率！", "goback", "", 2, "");
					&Footer();
					exit;
				}
				$sql .= "insert into ctninfo..Ffp_discount(Sales_ID,Airline_code,Air_ffp,Air_type,Class_code,Discount,ADiscount,Corp_ID,Sub_ID,Comm_rate,Dis_rate,Tag_char)
                  select '$Corp_center','$in{air_code}','$in{air_ffp}','X','$in{$class}',$in{$dis},isnull(b.ADiscount,$in{$dis}),a.Corp_ID,$f,0,$in{$agt},a.Tag_char
                    from ctninfo..Corp_ffp a, ctninfo..Ffp_discount b
                    where a.Corp_ID*=b.Corp_ID and a.Airline_code='$in{air_code}' and a.Air_ffp='$in{air_ffp}'
                      and a.Sales_ID='$Corp_center' and b.Sales_ID='$Corp_center' and b.Airline_code='$in{air_code}' and b.Air_ffp='$in{air_ffp}'
                      and b.Air_type='N' and b.Sub_ID=$f and Class_code='$in{$class}' and a.Corp_ID<>'$Corp_center'  \n";
				$sql .= "insert into ctninfo..Ffp_discount(Sales_ID,Airline_code,Air_ffp,Air_type,Class_code,Discount,ADiscount,Corp_ID,Sub_ID,Comm_rate,Dis_rate,Tag_char)
                  values ('$Corp_center','$in{air_code}','$in{air_ffp}','X','$in{$class}',$in{$dis},$in{$dis},'$Corp_center',$f,0,$in{$agt},'C') \n";
			}
			for (my $i=0;$i<$seatnum_Y{$f};$i++) {
				my $class = "class_Y_$i"."sub$f";
				my $dis = "dis_Y_$i"."sub$f";
				my $agt = "agt_Y_$i"."sub$f";
				my $fare = "fare_Y_$i"."sub$f";
				$sql .= "insert into ctninfo..Ffp_discount(Sales_ID,Airline_code,Air_ffp,Air_type,Class_code,Discount,Corp_ID,Sub_ID,Comm_rate,Dis_rate,Tag_char)
					values ('$Corp_center','$in{air_code}','$in{air_ffp}','Y','$in{$class}',$in{$dis},'$Corp_center',$f,0,$in{$agt},'C') \n";
			}
		}
		$sql .= "delete from ctninfo..Ffp_discount where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' and Air_type='N' \n";
		$sql .= "update ctninfo..Ffp_discount set Air_type='N' where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' and Air_type='X' \n";
	}
	elsif($in{action} eq "chg"){
		$sql .= qq! update ctninfo..Corp_ffp set Air_ffp='$in{new_ffp}' where Sales_ID='$Corp_center' and Air_ffp='$in{air_ffp}' and Airline_code='$in{air_code}'
			update ctninfo..Ffp_discount set Air_ffp='$in{new_ffp}' where Sales_ID='$Corp_center' and Airline_code='$in{air_code}' and Air_ffp='$in{air_ffp}'
			update ctninfo..Ffp_limit set Air_ffp='$in{new_ffp}' where Sales_ID='$Corp_center' and Airline_code='$in{air_code}' and Air_ffp='$in{air_ffp}'
			update ctninfo..Ffp_card set Air_ffp='$in{new_ffp}' where Sales_ID='$Corp_center' and Airline_code='$in{air_code}' and Air_ffp='$in{air_ffp}'
			update ctninfo..Ffp_info set Air_ffp='$in{new_ffp}' where Sales_ID='$Corp_center' and Airline_code='$in{air_code}' and Air_ffp='$in{air_ffp}' \n
			!;
	}
	elsif ($in{Type} eq "D" && $in{action} eq "mod"){ ## 似乎没有这种情况了吧？	 dabin@2014-09-25
		$in{air_ffp} =~ tr/a-z/A-Z/;
		$in{office_id} =~ s/，/,/;
		$in{depart_N} =~ s/，/,/;	$in{depart_N} =~ tr/a-z/A-Z/;
		$in{depart_Y} =~ s/，/,/;	$in{depart_Y} =~ tr/a-z/A-Z/;
		$in{arrive_N} =~ s/，/,/;	$in{arrive_N} =~ tr/a-z/A-Z/;
		$in{arrive_Y} =~ s/，/,/;	$in{arrive_Y} =~ tr/a-z/A-Z/;
		$in{class_N} =~ tr/a-z/A-Z/;	$in{class_Y} =~ tr/a-z/A-Z/;
		if ($in{task_num} eq "") {	$in{task_num}="null";		}
		
		$update_tag_int=",Tag_int=isnull(Tag_int,0)";
		if ($in{Status}==1) {
			$s_tag_int.="|1";
		}
		else{
			$s_tag_int.="&(~1)";
		}
		if ($in{ffp_type}==1) {	##二方协议
			$s_tag_int.="|8";
		}
		else{	##三方协议
			$s_tag_int.="&(~8)";
		}
		if ($in{reward_way}==1) {	##前返
			$s_tag_int.="|2&(~4)";
		}
		elsif($in{reward_way}==2){	##后返
			$s_tag_int.="&(~2)|4";
		}
		elsif($in{reward_way}==3){	##前后返
			$s_tag_int.="|2|4";
		}
#		if ($in{auto_command} == 1){ ## sfc前自动做RMK IC指令
#			$s_tag_int.="|16";
#		}else{
#			$s_tag_int.="&(~16)";
#		}
		$update_tag_int.=$s_tag_int;
		
		$sql .= "update ctninfo..Ffp_info set Task_num=$in{task_num},Office_ID='$in{office_id}',Depart_N='$in{depart_N}',Arrive_N='$in{arrive_N}',
			Class_N='$in{class_N}',Depart_Y='$in{depart_Y}',Arrive_Y='$in{Arrive_Y}',Class_Y='$in{class_Y}',Comment='$in{comment}',User_ID='$in{User_ID}',Op_time=getdate() $update_tag_int 
			where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' \n";
	}
	elsif ($in{Type} eq "B" && $in{action} eq "add"){ ## 旅客信息维护
		if ($in{card_id} eq "" && $in{user_name} eq "") {
			print &showMessage("错误提示", "请至少输入证件号码或姓名中的一个", "goback", "", 2, "");
			&Footer();
			exit;
		}
		## 查询是否存在录入或修改的三方协议号
		my $is_exist="";
		$sql_t = "select Airline_code,Air_ffp,Card_ID from ctninfo..Ffp_card
			where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Air_ffp = '$in{air_ffp}' \n";
		if ($in{card_id} ne "") {
			$sql_t .= " and Card_ID = '$in{card_id}' \n";
		}
		if ($in{user_name} ne "") {
			$sql_t .= " and User_name = '$in{user_name}' \n";
		}

		$db->ct_execute($sql_t);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$is_exist="对不起，输入的证件号码$in{card_id}或姓名$in{user_name}在$in{air_code}三方协议号$in{air_ffp}中已存在，请重新输入！";
				}
			}
		}
		if ($is_exist ne "") {
			print &showMessage("错误提示", "$is_exist", "goback", "", 2, "");
			&Footer();
			exit;
		}
		$in{air_ffp} =~ tr/a-z/A-Z/;
		$sql .= "if exists (select * from ctninfo..Ffp_card where Sales_ID='$Corp_center')
			select \@s_id=max(Serial_id)+1 from ctninfo..Ffp_card where Sales_ID='$Corp_center'
			else select \@s_id=1 \n";
		$sql .= " insert into ctninfo..Ffp_card(Sales_ID,Serial_id,Airline_code,Air_ffp,Card_ID,Comment,User_ID,Op_time,User_name)
			values ('$Corp_center',\@s_id,'$in{air_code}','$in{air_ffp}','$in{card_id}','$in{comment}','$in{User_ID}',getdate(),'$in{user_name}') \n";
	}
	elsif ($in{Type} eq "B" && $in{action} eq "del"){
		if ($in{del_all} eq "Y") {
			$sql .= "delete from ctninfo..Ffp_card where Sales_ID = '$Corp_center' and Airline_code = '$in{aircode_for_del}' and Air_ffp = '$in{ffp_for_del}' \n";
		}else{
			for (my $i=0;$i<$in{i_num};$i++) {
				my $cb = "cb_$i";
				my $s_id = "s_id_$i";
				if ($in{$cb} ne "") {
					$sql .= "delete from ctninfo..Ffp_card where Sales_ID = '$Corp_center' and Serial_id =$in{$s_id} \n";
				}
			}
		}
		if ($in{s_id} ne "") {
			$sql .= "delete from ctninfo..Ffp_card where Sales_ID = '$Corp_center' and Serial_id =$in{s_id} \n";
		}
	}
	elsif ($in{Type} eq "B" && $in{action} eq "mod"){
		$sql .= "update ctninfo..Ffp_card set Airline_code='$in{air_code}',Air_ffp='$in{air_ffp}',Card_ID='$in{card_id}',User_name='$in{user_name}' where Sales_ID='$Corp_center' and Serial_id =$in{s_id} \n";
	}
	
	$Update = 0;
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
			$Update=1;
			next;
		}
	}
	if($Update eq '1') {
		$db->ct_execute("Commit Transaction sql_insert");
		#$db->ct_execute("Rollback Transaction sql_insert");
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
				}
			}
		}
		if($in{Type} eq "E" && $in{new_ffp} ne ""){
			$in{air_ffp}=$in{new_ffp};
		}
		my $uri_ffp=&uri_escape($in{air_ffp});
		print &showMessage("系统提示", "信息维护成功！", "/cgishell/golden/admin/manage/ffp_info.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Type=$in{Type}&air_code=$in{air_code}&air_ffp=$uri_ffp", "", 1, "");
		&Footer();
		exit;
	}
	else{
		$db->ct_execute("Rollback Transaction sql_insert");
		print &showMessage("错误提示", "对不起，数据写入失败！", "goback", "", 2, "");
		&Footer();
		exit;
	}
}
my $uri_ffp=&uri_escape($in{air_ffp});
my $hrefs = "ffp_info.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}";
my $a_href = "$hrefs&Type=A";
my $b_href = "$hrefs&Type=B";
my $c_href = "$hrefs&Type=C";
my $d_href = "$hrefs&Type=D";
my $e_href = "$hrefs&Type=E";
my $f_href = "$hrefs&Type=F";
my $a_bg=$b_bg=$c_bg="";
if ($in{Type} eq "") {	$in{Type}="A";	}
if ($in{Type} eq "B") {	$b_bg=" class='current'";	}
elsif ($in{Type} eq "C") {	$c_bg=" class='current'";	}
elsif ($in{Type} eq "D") {	$d_bg=" class='current'";	}
elsif ($in{Type} eq "E") {	$e_bg=" class='current'";	}
elsif ($in{Type} eq "F") {	$f_bg=" class='current'";	}
else{	$a_bg = " class='current'";	}
if ($in{air_type} eq "N") {	$ck_n="checked";	}
elsif ($in{air_type} eq "Y") {	$ck_y="checked";	}
else{	$ck_a="checked";	}

print qq`
<link rel="stylesheet" type="text/css" href="/admin/style/style.css">
<script type="text/javascript" src="/admin/js/popwin.js"></script>
<script type="text/javascript" src="/admin/js/dblcalendar/calendar.js"></script>
<div id="append_parent"></div>
<h1 id="PageHeadtitle"><strong>配置</strong> - 三方协议</h1>
<div id="append_parent"></div>
<div class="wrapper" id="setting_customer">
	<div class="tabNav" id="parameter_tabs">
		<ul>`;
			if ($in{Type} eq "B") {
				print qq`<li $b_bg><a href="$b_href&air_code=$in{air_code}&air_ffp=$uri_ffp"><img src="/admin/index/images/confirm.gif" />绑定旅客信息号码</a></li>`;
			}
			else{
				print qq`<li $a_bg><a href="$a_href"><img src="/admin/images/icon_base/icon_002.gif" />协议维护</a></li>`;
			}
			if ($in{Type} eq "E") {
				print qq`<li $e_bg><a href="$e_href&air_code=$in{air_code}&air_ffp=$uri_ffp"><img src="/admin/images/icon_base/icon_002.gif" />修改协议</a></li>`;
			}
			else{
				print qq`<li $d_bg><a href="$d_href"><img src="/admin/images/icon_base/icon_001.gif" />增加协议</a></li>`;
			}
			print qq`<li $c_bg><a href="$c_href"><img src="/admin/images/icon_base/icon_007.gif" />销售统计</a></li>`;
			print qq`<li $f_bg><a href="$f_href"><img src="/admin/images/icon_base/icon_007.gif" />资料收集</a></li>`;
			print qq`
		</ul>
	</div>
	<dl>`;

if ($in{Type} eq "C") {	## 销售统计	dabin@2011-4-24
	if ($in{Tk_type} eq "") {$in{Tk_type}="Y";}
	$tkt_type=&get_dict($Corp_center,3,"$in{Tk_type}","list");
	$today = &cctime(time);
	($week,$month,$day,$time,$year)=split(" ",$today);
	if($day<10){$day="0".$day;}
	$today = $year.".".$month."."."$day";

	## 月份列表
	my $c_month="$year.$month";
	if ($in{cur_month} eq "") {	$in{cur_month} = $c_month;	}
	$month += 2;
	if($month>12) {
		$year++;
		$month -=12;
	}
	my $t_text="| ";
	for (my $i=0;$i<26;$i++) {
		if ($month < 10 && length($month)< 2 ) {	$month="0".$month;	}
		$c_month="$year.$month";
		if ($c_month >= '2011.04') {
			if ($c_month eq $in{cur_month}) {
				$month_list .= "<option value='$c_month' selected>$c_month</option>";
				if ($i < 12) {
					$t_text .= "<a href='report.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&cur_month=$c_month'><font color=green><b>$c_month</b></font></a> | \n";
				}
			}
			else{
				$month_list .= "<option value='$c_month'>$c_month</option>";
				if ($i < 12) {
					$t_text .= "<a href='report.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&cur_month=$c_month'>$c_month</a> | \n";
				}
			}
		}
		$month --;
		if ($month == 0) {	$month=12;	$year--;	}
	}
	if ($in{is_down} eq "Y") {
		$ck_is_down="checked";
	}
	my ($c_ckA,$c_ckB,$title)=();
	if ($in{date_type} eq "") {$in{date_type}="A";}
	if ($in{date_type} eq "A") {
		$c_ckA="checked";
		$title="航班起飞日期";
	}elsif ($in{date_type} eq "B") {
		$c_ckB="checked";
		$title="订单出票日期";
	}
	my ($Air_type_ALL,$Air_type_N,$Air_type_Y)=();
	if ($in{Air_type} eq "N") {
		$Air_type_N="checked";
	}elsif($in{Air_type} eq "Y"){
		$Air_type_Y="checked";
	}else{
		$Air_type_ALL="checked";
		$in{Air_type}="";
	}
	if ($in{air_code} eq "") {$in{air_code} = "3U";}
	print qq!
	<div class="wrapper">
		<dl><dt>三方协议销售统计<font color=red style='font-size:9pt;'>（按$title\统计）</font></dt></dl>
	</div>
	<form action="ffp_info.pl" method="post" name="query">
	<table cellspacing="1" bgcolor="#C0C7D9" width=100% align=center>
		<tr bgcolor=f0f0f0><td>
			<table border=0 cellpadding=0 cellspacing=1 width=100%>
				 <tr>
					<td height=25 width=240><b>航空公司：</b><input type="text" name="air_code"  onkeyup="this.value=this.value.toUpperCase();" style="width:140px;" value="$in{air_code}" cust_pin="right" cust_title="航司名称" rigor="rigor" cust_changes="ALL" custSug="0" ajax_url="/cgishell/golden/admin/manage/get_ffp.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Form_type=airlines"></td>
					<td width=150><b>票证类型：</b><select name="Tk_type"><option value=''>全部</option>$tkt_type</select></td>
					<td width=240><b>日期类型：</b>
						<label for="date_type1"><input type="radio" name="date_type" id="date_type1" OnClick="refer();" value="A" $c_ckA>起飞日期</label>
						<label for="date_type2"><input type="radio" name="date_type" id="date_type2" OnClick="refer();" value="B" $c_ckB>出票日期</label>
					</td>
					<td width=240><b>类型：</b>
						<label for="Air_type_ALL"><input type="radio" name="Air_type" id="Air_type_ALL" OnClick="refer();" value="" $Air_type_ALL>全部</label>
						<label for="Air_type_N"><input type="radio" name="Air_type" id="Air_type_N" OnClick="refer();" value="N" $Air_type_N>国内</label>
						<label for="Air_type_Y"><input type="radio" name="Air_type" id="Air_type_Y" OnClick="refer();" value="Y" $Air_type_Y>国际</label>
					</td>
					<td width=80><select name=cur_month>$month_list</select></td>
					<td><label for='is_down'><input type=checkbox name=is_down id=is_down value="Y" $ck_is_down /><b>下载报表</label></td>
					<td align=right>
						<input type=hidden name=User_ID value='$in{User_ID}'>
						<input type=hidden name=Serial_no value='$in{Serial_no}'>
						<input type=hidden name=Type value='$in{Type}'>
						<input type=hidden name=query value='Y'>
						<input type=submit value=' 统 计 ' class=btn30>
					</td>
				</tr>
			</table>
		</td></tr>
	</table>
	<script language='javascript'>
		function refer(){
			document.query.submit();
		}
	</script>
	</form>!;
	if ($in{query} eq "Y") {
		$sql =" select convert(char(10),dateadd(month,1,'$in{cur_month}.01'),102)";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$next_month=$row[0];
				}
			}
		}
		if ($in{User_ID} eq "admin") {
			$debug_sql="Y";
		}
		print qq!<form action="ffp_info.pl" name=new_detail target=ffp_detail method=post style="padding:0;margin:0;" >
		<input type=hidden name=User_ID value="$in{User_ID}" />
		<input type=hidden name=Serial_no value="$in{Serial_no}" />
		<input type=hidden name=reportID   value="FFP001" />
		<input type=hidden name=air_code value="$in{air_code}" />
		<input type=hidden name=Corp_ffp value="" />
		<input type=hidden name=debug_sql value="$debug_sql" />
		<input type=hidden name=date_type value="$in{date_type}" />
		<input type=hidden name=Air_type value="$in{Air_type}" />
		<input type=hidden name=cur_month value="$in{cur_month}" />
		<input type=hidden name=new_temp value="Y" />
		<input type=hidden name=Alert_status value="" />
		<input type=hidden name=Tk_type value="$in{Tk_type}" />
		</form>
		<script language=javascript>
		function fp_detail(c_ffp,a_status){
			document.new_detail.Corp_ffp.value=c_ffp;
			document.new_detail.Alert_status.value=a_status;
			document.new_detail.submit();
		}
		</script>!;
		print qq!<br>
			<table width="100%" cellspacing="1" bgcolor="#C0C7D9">
			<tr bgcolor=f2f2f2 align=center>
			<td rowspan=2>三方协议号</td>
			<td rowspan=2>客户</td>
			<td colspan=2>正常</td>
			<td colspan=2>退票</td>
			<td colspan=2>做废</td>
			<td colspan=2>小计</td>
			<td rowspan=2 width=8%>任务量</td>
			<td rowspan=2 width=8%>完成比例</td>
			</tr>

			<tr bgcolor=f2f2f2 align=center>
			<td width=8%>航段数</td>
			<td width=8%>票款(万)</td>
			<td width=8%>航段数</td>
			<td width=8%>票款(万)</td>
			<td width=8%>航段数</td>
			<td width=8%>票款(万)</td>
			<td width=8%>航段数</td>
			<td width=8%>票款(万)</td>
			</tr>!;
		my $t_num;
		$sql = "select a.Corp_ffp,a.Alert_status,sum(c.Out_price),count(*)
			from ctninfo..Airbook_$Top_corp a,
				ctninfo..Airbook_lines_$Top_corp b,
				ctninfo..Airbook_detail_$Top_corp c
			where a.Reservation_ID=b.Reservation_ID
				and b.Reservation_ID=c.Reservation_ID
				and b.Res_serial=c.Res_serial
				and a.Sales_ID = '$Corp_center'
				and b.Sales_ID = '$Corp_center'
				and c.Sales_ID = '$Corp_center' ";
		if ($in{date_type} eq "A") {
			$sql .= "and b.Air_date >= '$in{cur_month}.01'
				and b.Air_date < dateadd(month,1,'$in{cur_month}.01') ";
		}else{
			$sql .= "and a.Ticket_time >= '$in{cur_month}.01'
				and a.Ticket_time < dateadd(month,1,'$in{cur_month}.01') ";
		}
		if ($in{Air_type} ne "") {
			$sql .= "and a.Air_type='$in{Air_type}' ";
		}
		if($in{Tk_type} ne ""){
			$sql .= "and c.Is_ET='$in{Tk_type}' ";
		}
		$sql .= "and b.Airline_ID='$in{air_code}'
				and a.Corp_ffp+'' <> '' and a.Book_status<>'C'
			group by a.Corp_ffp,a.Alert_status
			order by a.Corp_ffp,a.Alert_status ";
		#print "<pre>$sql";exit;
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$total{$row[0]}[$row[1]]=int($row[2]);
					$num{$row[0]}[$row[1]]=$row[3];
					$ffp_infos{$row[0]}=0;  ##有时候修改维护页面的协议号就统计不出来了，所以以订单的为准   liangby@2013-2-26
					$t_num++;
				}
			}
		}
		## 查询协议号信息
		$sql = "select Air_ffp,rtrim(Comment),Task_num from ctninfo..Ffp_info
			where Sales_ID = '$Corp_center' and Airline_code ='$in{air_code}' and Sub_ID=0 order by Air_ffp \n";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$ffp_name{$row[0]}=$row[1];
					$ffp_task{$row[0]}=$row[2];
					$ffp_infos{$row[0]}=1;
				}
			}
		}
		if ($in{is_down} eq "Y") {##下载报表   liangby@2011-4-28
			my $r_path="d:/www/Corp_extra/";
			if (! -e $r_path) {#目录不存在
				 mkdir($r_path,0002);
			}elsif(!-d $r_path){#存在文件但不是目录
				 mkdir($r_path,0002);
			}
			my $path="d:/www/Corp_extra/$Corp_ID/";
			if (! -e $path) {#目录不存在
				 mkdir($path,0002);
			}elsif(!-d $path){#存在文件但不是目录
				 mkdir($path,0002);
			}
			# 新建一个Excel文件
			my $ttime=$time;
			$ttime=~ s/\:*//g;
			my $ttoday=$today;
			$ttoday=~ s/\.*//g;
			my $context = new MD5;
			$context->reset();
			$context->add($Corp_ID."ffp_info".$ttoday.$ttime."richongqianlimugengshangyicenglou");
			my $md5_filename = $context->hexdigest;
			$BUF= $path.$md5_filename.".xls";
			$del_link="d:/www/Corp_extra/$Corp_ID/";
			$workbook;
			$workbook= Spreadsheet::WriteExcel::Big->new($BUF);
			# 新键一个工作簿
			$worksheet = $workbook->addworksheet("三方协议销售统计");

			##数据格式
			$format1 = $workbook->addformat();
			$format2 = $workbook->addformat();
			$format3 = $workbook->addformat();
			## 9号字体
			$format1->set_size(9);
			$format1->set_color('black');
			$format1->set_align('right');

			$format2->set_size(9);
			$format2->set_color('black');
			$format2->set_align('center');

			$format3->set_size(9);
			$format3->set_color('black');
			$format3->set_align('right');

			my $format="";
			## ----------------------------------------------------------------------------

			$iRow=1;
			my $max_rows=64000;

			$worksheet->merge_range(0,0,0,11," 三方协议销售汇总,统计月份$in{cur_month}",$format2);
			$worksheet->merge_range($iRow,0,$iRow+1,0,"三方协议号",$format2);
			$worksheet->merge_range($iRow,1,$iRow+1,1,"客户",$format2);
			$worksheet->merge_range($iRow,2,$iRow,3,"正常",$format2);
			$worksheet->merge_range($iRow,4,$iRow,5,"退票",$format2);
			$worksheet->merge_range($iRow,6,$iRow,7,"作废",$format2);
			$worksheet->merge_range($iRow,8,$iRow,9,"小计",$format2);
			$worksheet->merge_range($iRow,10,$iRow+1,10,"任务量",$format2);
			$worksheet->merge_range($iRow,11,$iRow+1,11,"完成比列",$format2);
			$iRow++;
			@Caltxt = ("航段数","票款","航段数","票款","航段数","票款","航段数","票款");
			for (my $i=0;$i<scalar(@Caltxt) ;$i++) {
				my $it=$i+2;
			   $worksheet->write_string($iRow,$it,$Caltxt[$i],$format2);
			}
		}
		my @ffp_infos=keys %ffp_infos;
		@ffp_infos=sort {$ffp_infos{$b}<=>$ffp_infos{$a}} @ffp_infos;  ##维护的排在前面
		foreach my $tkk (@ffp_infos) {
			my ($t_sum,$t_num)=(0,0);
			if ($in{is_down} eq "Y") {
				$iRow++;

				$j=0;
				$worksheet->write_string($iRow,$j,"$tkk",$format);
				$j++;
				$worksheet->write_string($iRow,$j,"$ffp_name{$tkk}",$format);
			}
			print "<tr bgcolor=ffffff align=right>
				<td height='20' align=left>$tkk</td>
				<td align=left>$ffp_name{$tkk}&nbsp;</td>";
			for (my $i=0;$i<=2;$i++) {
				if ($total{$tkk}[$i] != 0) {
					my $t_task = sprintf("%.4f",$total{$tkk}[$i]/10000);
					print "<td>$num{$tkk}[$i]</td>
						<td>$t_task</td>\n";
					$t_sum+=$t_task;
					if ($i==0) {
						$t_num=$num{$tkk}[$i];
					}
					else{
						$t_num=$t_num-$num{$tkk}[$i];
					}
					if ($in{is_down} eq "Y") {
						$j++;
						$worksheet->write_number($iRow,$j,$num{$tkk}[$i],$format);
						$j++;
						$worksheet->write_number($iRow,$j,$t_task,$format);
					}
				}
				else{
					if ($in{is_down} eq "Y") {
						$j=$j+2;
					}
					print "<td>&nbsp;</td><td>&nbsp;</td>\n";
				}
			}
			my $t_per;
			if ($ffp_task{$tkk} ne "" && $ffp_task{$tkk} >0) {
				$t_per=sprintf("%.2f",$t_sum/$ffp_task{$tkk})*100;
			}

			print qq!<td><a href="javascript:fp_detail('$tkk','');" title="明细">$t_num</a></td><td>$t_sum</td>
				<td>$ffp_task{$tkk}</td>
				<td>$t_per%</td></tr>!;
			if ($in{is_down} eq "Y") {
					$j++;
					$worksheet->write_number($iRow,$j,$t_num,$format);
					$j++;
					$worksheet->write_number($iRow,$j,$t_sum,$format);
					$j++;
					$worksheet->write_string($iRow,$j,"$ffp_task{$tkk}",$format);
					$j++;
					$worksheet->write_string($iRow,$j,"$t_per%",$format);

				}

		}
		print qq!
			</table>!;
		if ($in{is_down} eq "Y") {
			$workbook->close;
			## 写Excel结束-------------------------------------------------------
			my $fileName = $BUF;
			$fileName =~ s/^.*(\\|\/)//; #用正则表达式去除无用的路径名，得到文件名
			$D_SERVER=$G_SERVER;
			$downfile='/Corp_extra/'.$Corp_ID.'/'.$fileName;
			print qq!<table><tr><td>下载地址：<a href=$downfile  ><img src='/admin/images/download2.gif' border=0><font class=medium><b>下载</b></font></a></td></tr></table>!;
		}

	}
	#exit;
}
elsif ($in{Type} eq "A") {
	print qq`
	<div class="wrapper">
		<dl><dt>查询三方协议号</dt></dl>
	</div>
	<form action="ffp_info.pl" method="post" name="query">
	<table cellspacing="1" bgcolor="#C0C7D9" width=100% align=center>
		<tr bgcolor=f0f0f0><td>
			<table border=0 cellpadding=0 cellspacing=1 width=100%>
				 <tr>
					<td height=25><b>航空公司：</b></td>
					<td><input type="text" name="air_code"  onkeyup="this.value=this.value.toUpperCase();" style='width:150px;' value="$in{air_code}" cust_pin="right" cust_title="航司名称" rigor="rigor" cust_changes="ALL" custSug="0" ajax_url="/cgishell/golden/admin/manage/get_ffp.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Form_type=airlines"></td>
					<td><b>客  户：</b></td><td><input  type="text" style='width:150px;' name="client" value="$in{client}"></td>
					<td><b>三方协议号：</b></td>
					<td><input type=text name=air_ffp size=10 class="inputStyle" ></td>
					<td><b>有效期：</b></td>
					<td>
						<input type=text name=Start_date id=sdate size=12 maxLength=10 value="$in{Start_date}" class="inputStyle" onclick="event.cancelBubble=true;showCalendar('sdate',true,'sdate','','','','','','','','text','sdate');"> -
						<input type=text name=End_date id=edate size=12 maxLength=10 value="$in{End_date}" class="inputStyle" onclick="event.cancelBubble=true;showCalendar('edate',true,'edate','','','','','','','','text','edate');">
					</td>
					<td align=center>
						<input type=hidden name=User_ID value='$in{User_ID}'>
						<input type=hidden name=Serial_no value='$in{Serial_no}'>
						<input type=hidden name=Type value='$in{Type}'>
						<input type=submit value=' 查 询 ' class=btn30>
					</td>
				 </tr>
			 </table>
		</td></tr>
	</table>
	</form>
	<br>
	<table width=100% align=center cellspacing="1" bgcolor="#C0C7D9">
		<tr bgcolor=f0f0f0 align=center>
			<td rowspan=2>航司</td>
			<td rowspan=2>协议号</td>
			<td rowspan=2>客户</td>
			<td rowspan=2>Office</td>
			<td rowspan=2>任务量</td>
			<td colspan=3 height=20>国内</td>
			<td colspan=3>国际</td>
			<td rowspan=2>有效期</td>
			<td rowspan=2>状态</td>
			<td rowspan=2>操作</td>
		</tr>
		<tr bgcolor=f0f0f0 align=center>
			<td height=20>始发城市</td>
			<td>抵达城市</td>
			<td>限制舱位</td>
			<td>始发城市</td>
			<td>抵达城市</td>
			<td>限制舱位</td>
		</tr>`;
	## 统计绑定客户数量	dabin@2013-01-18
	$sql = "select a.Airline_code,a.Air_ffp,a.Tag_char,count(*)
		from ctninfo..Corp_ffp a,ctninfo..Ffp_info b
		where a.Sales_ID = '$Corp_center'
			and b.Sales_ID = '$Corp_center'
			and b.Sub_ID=0
			and a.Airline_code=b.Airline_code
			and a.Air_ffp=b.Air_ffp 
			and a.Tag_char IN(NULL, '','C')\n";
	if ($in{air_code} ne "") {$sql .= " and b.Airline_code='$in{air_code}' \n";}
	if ($in{client} ne "") {	$where .= " and Comment='$in{client}' \n";		}
	if ($in{air_ffp} ne "") {$sql .= " and b.Air_ffp='$in{air_ffp}' \n";}
	if ($in{Start_date} ne "") {$sql .= " and (b.End_date>='$in{Start_date}' or b.End_date is null) \n";}
	if ($in{End_date} ne "") {$sql .= " and (b.Start_date<='$in{End_date}' or b.Start_date is null) \n";}
	$sql .= "group by a.Airline_code,a.Air_ffp,a.Tag_char
		order by a.Airline_code,a.Air_ffp,a.Tag_char \n";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				if ($row[2] eq "" || $row[2] eq "C") {
					$corpnum{"$row[0]$row[1]"}=$row[3];
				}elsif($row[2] eq "U"){
					$useridnum{"$row[0]$row[1]"}=$row[3];
				}
			}
		}
	}
	## 统计绑定旅客数量	dabin@2014-04-29
	$sql = "select a.Airline_code,a.Air_ffp,count(*)
		from ctninfo..Ffp_card a,ctninfo..Ffp_info b
		where b.Sales_ID = '$Corp_center'
			and b.Sub_ID=0
			and a.Airline_code=b.Airline_code
			and a.Air_ffp=b.Air_ffp \n";
	if ($in{air_code} ne "") {$sql .= " and b.Airline_code='$in{air_code}' \n";}
	if ($in{client} ne "") {	$where .= " and Comment='$in{client}' \n";		}
	if ($in{air_ffp} ne "") {$sql .= " and b.Air_ffp='$in{air_ffp}' \n";}
	if ($in{Start_date} ne "") {$sql .= " and (b.End_date>='$in{Start_date}' or b.End_date is null) \n";}
	if ($in{End_date} ne "") {$sql .= " and (b.Start_date<='$in{End_date}' or b.Start_date is null) \n";}
	$sql .= "group by a.Airline_code,a.Air_ffp
		order by a.Airline_code,a.Air_ffp \n";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$usernum{"$row[0]$row[1]"}=$row[2];
			}
		}
	}

	$where = " from ctninfo..Ffp_info where Sales_ID = '$Corp_center' and Sub_ID=0 \n";
	if ($in{air_code} ne "") {	$where .= " and Airline_code='$in{air_code}' \n";		}
	if ($in{client} ne "") {	$where .= " and Comment='$in{client}' \n";		}
	if ($in{air_ffp} ne "") {	$where .= " and Air_ffp='$in{air_ffp}' \n";		}
	if ($in{Start_date} ne "") {	$where .= " and (End_date>='$in{Start_date}' or End_date is null) \n";		}
	if ($in{End_date} ne "") {	$where .= " and (Start_date<='$in{End_date}' or Start_date is null) \n";		}
	$sql = "select count(*) ".$where;
	$Total_num=&Exec_sql();
	if ($Total_num == 0) {
		print qq`<tr bgcolor=f0f0f0><td height=20 colspan='14'><font color=red>对不起，没有找到相关记录！</font></td></tr>
			</table>`;
		exit;
	}

	## 生成查询游标
	my $records = $in{perpage} eq '' ? 20 : $in{perpage};
	$Start = $in{Start};
	if($in{Start} eq "" || $in{Start} eq " ") { $Start=1; }
	my $t_records = $records*$Start;
	$sql = " select top $t_records Airline_code,Air_ffp,rtrim(Office_ID),Task_num,Depart_N,Class_N,Depart_Y,Class_Y,Comment,User_ID,Op_time,convert(char(10),Start_date,102),convert(char(10),End_date,102),Sub_ID,Arrive_N,Arrive_Y,Tag_int,datediff(day,getdate(),End_date) \n";
	$sql .= $where;
	$sql .= " order by Airline_code,Air_ffp,Sub_ID \n";
	$Find_res = 1;
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				if($Find_res<=$Start*$records && $Find_res>($Start-1)*$records ){
					my $tt="$row[0]$row[1]";
					my $corp_num=$corpnum{$tt};
					if ($corp_num > 0) {
						$corp_num="[<font color=red>$corp_num</font>]";
					}
					my $user_num=$usernum{$tt};
					if ($user_num > 0) {
						$user_num="[<font color=red>$user_num</font>]";
					}
					my $userid_num=$useridnum{$tt};
					if ($userid_num > 0) {
						$userid_num="[<font color=red>$userid_num</font>]";
					}
					my $air_type="全部";
					if ($row[3] eq "N") {	$air_type="国内";		}
					elsif ($row[3] eq "Y") {	$air_type="国际";	}
					$row[4]=&cut_str($row[4],20);
					my $valid_date=qq!$row[11]-$row[12]!; my $font_color;
					if ($row[17] >= 0 && $row[17] < 30 && $row[17] ne ""){ # 一个月按30天算
						$font_color="style=color:red;";
					}
					if ($row[11] eq "" && $row[12] eq "") {
						$valid_date=qq!<font title="开始日期与结束日期为空则不限制">不限制</font>!;
					}
					if ($row[2] eq "") {	$row[2]=$Corp_center;	}
					my $tn=&cut_str($row[5],16);
					my $ty=&cut_str($row[7],16);
					my $status='启用';
					if($row[16]&1==1) { $status='暂停';}
					my $uri_ffp_d=&uri_escape($row[1]);
					my $uri_ffp_dd=&uri_escape($uri_ffp_d);
					print qq!
					<tr bgcolor=f0fff0 title='操作人：$row[9] 操作时间：$row[10]'>
						<td height=20>$row[0] $row[17]</td>
						<td>$row[1]</td>
						<td>$row[8]</td>
						<td>$row[2]</td>
						<td align=right>$row[3]&nbsp;</td>
						<td>$row[4]&nbsp;</td>
						<td>$row[14]&nbsp;</td>
						<td title='$row[5]'>$tn&nbsp;</td>
						<td>$row[6]&nbsp;</td>
						<td>$row[15]&nbsp;</td>
						<td title='$row[7]'>$ty&nbsp;</td>
						<td align=center $font_color>$valid_date</td>
						<td>$status</td>
						<td><a href="ffp_info.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Type=E&air_code=$row[0]&air_ffp=$uri_ffp_d" title='修改'>修改</a>
							<a href="javascript:if(confirm('确定要删除此三方协议号吗?'))location='ffp_info.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Type=$in{Type}&action=del&air_code=$row[0]&air_ffp=$uri_ffp_dd'" title='删除'>删除</a>
							<a href="javascript:ffp_acl('$row[0]','$uri_ffp_dd')" >绑定客户$corp_num</a>
							<a href="ffp_info.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Type=B&air_code=$row[0]&air_ffp=$uri_ffp_d" title='绑定旅客信息'>绑定旅客$user_num</a>
							<a href="javascript:ffpuser_acl('$row[0]','$uri_ffp_dd')" title='绑定会员信息'>绑定会员$userid_num</a>
						</td>
					</tr>!;
				}
				$Find_res ++;
			}
		}
	}

	my $pageButtons = &showPages($Total_num, $records, $Start, 10, '', 1);
	print qq`
	<tr bgcolor=f0f0f0>
		<td height=20 colspan='14'>
			<div style="clear: both; padding: 5px 0;">
				$pageButtons
			</div>
		</td>
	</tr>`;
	print qq`</table>
	<script>
	function ffp_acl(air_code,air_ffp){
		window.open('ffp_acl.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&air_code='+air_code+'&air_ffp='+air_ffp,'_new');
	}
	function ffpuser_acl(air_code,air_ffp){
		window.open('ffp_acl.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Type=C&air_code='+air_code+'&air_ffp='+air_ffp,'_ffpuser_acl');
	}
	function OpenWindow(theURL,winName,features) {
		window.open(theURL,winName,features);
	 }
	</script>`;
}
elsif ($in{Type} eq "D" || $in{Type} eq "E") {
	my $title_name="增加三方协议号";  my $op_name = "确认增加";  my $upfile_htm; 
	if ($in{Type} eq "E") {
		$title_name="修改三方协议号";	$op_name = "确认修改";
		
		$sql = " select Sub_ID,rtrim(Airline_code),Air_ffp,Task_num,Office_ID,rtrim(Depart_N),rtrim(Class_N),rtrim(Depart_Y),
				rtrim(Class_Y),rtrim(Comment),convert(char(10),Start_date,102),convert(char(10),End_date,102),rtrim(Ref_office),Isnull(Dis_rate,0),Arrive_N,Arrive_Y,Tag_int,Core_memo,Info_memo,File_name
			from ctninfo..Ffp_info where Sales_ID='$Corp_center' and Airline_code='$in{air_code}' and Air_ffp='$in{air_ffp}' \n";
		#print "<pre>$sql</pre>";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					if ($air_code{$row[1]} ne "") {
						$air_code=$air_code{$row[1]};
					}else{
						$air_code=$row[1];
					}
					
					$task_num=$row[3];
					$office_id=$row[4];
					$depart{$row[0]}=$row[5];
					$arrive{$row[0]}=$row[14];
					$class{$row[0]}=$row[6];
					$depart_y{$row[0]}=$row[7];
					$arrive_y{$row[0]}=$row[15];
					$tag_int=$row[16];
					$class_y{$row[0]}=$row[8];
					$comment=$row[9];
					$Start_date=$row[10];
					$End_date=$row[11];
					$Sub_be{$row[0]}="Y";
					($Ref_office1,$Ref_office2)=split/,/,$row[12];
					if ($row[13] eq "") {	$row[13]=0;	}
					$Comm_rate_N{$row[0]}=$row[13];
					$core_note=$row[17];
					$info_note=$row[18];
					$file_name=$row[19];
				}
			}
		}
		$sql = " select Sub_ID,Class_code,Discount,Air_type,Isnull(Dis_rate,0) from ctninfo..Ffp_discount
			where Sales_ID='$Corp_center' and Airline_code='$in{air_code}'
				and Air_ffp='$in{air_ffp}' and Corp_ID='$Corp_center'
				and Tag_char in(null,'','C')
			order by Sub_ID \n";
		#print "<pre>$sql</pre>";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					if ($d_num{$row[0]} eq "") {$d_num{$row[0]}=0;}
					if ($d_num_y{$row[0]} eq "") {$d_num_y{$row[0]}=0;}
					my $d_num_ys=$d_num_y{$row[0]};
					my $d_nums=$d_num{$row[0]};
					if ($row[3] eq "Y") {
						$dclass_y[$d_num_ys]{$row[0]}=$row[1];
						$dis_y[$d_num_ys]{$row[0]}=$row[2];
						$agt_y[$d_num_ys]{$row[0]}=$row[4];
						$d_num_y{$row[0]}++;
					}else{
						$dclass[$d_nums]{$row[0]}=$row[1];
						$dis[$d_nums]{$row[0]}=$row[2];
						$agt[$d_nums]{$row[0]}=$row[4];
						$d_num{$row[0]}++;
					}
				}
			}
		}
	}else{ 
	   ## 上传文档		jf@2018-01-10
	   $upfile_htm=qq`<table cellspacing="1">
			<tr>
				<td height=30 width='60px'>附件上传：</td>
				<td>
					<form name="Upload" action="/cgishell/golden/admin/manage/upload_ffpinfo.pl" method="post" enctype="multipart/form-data" target="UploadWindow" class="file_box_s1" id="fileup" style="display:inline;">
						<input type="file" name="NewFile" class="file" id="NewFile" size="28" onchange="fileChange();" />
						<span id="return_error"></span>
						<input type=hidden name="User_ID" value="$in{User_ID}">
						<input type=hidden name="Serial_no" value="$in{Serial_no}">
						<input type=hidden name="Type" value="upffp">
					</form>
					<span id='fileshow'></span>&nbsp;&nbsp;&nbsp;<span id='fileshow1' style="color:#B50729"></span>
				</td>
			</tr>
		</table>
		<iframe name="UploadWindow" style="display:none;" src=""><\/iframe>
		<script type="text/javascript" src="/admin/js/ajax/jquery-1.3.2.min.js" charset="gb2312"></script>
		<script type="text/javascript">
		    var isIE = /msie/i.test(navigator.userAgent) && !window.opera;	// 判断是否IE浏览器
			function fileChange( ) {
			  var fileSize = 0,	
				  size,  
			      filetypes = [".jpg",".gif",".jpeg",".png",".bmp",".7z",".aiff",".asf",".avi",".csv",".doc",".docx",".flv",".gz",".gzip",".mid",".mov",".mp3",".mp4",".mpeg",".mpg",".pdf",".rtf",".ppt",".pptx",".ram",".rar",".rmi",".rmvb",".tar",".tgz",".tif",".tiff",".txt",".vsd",".wav",".wma",".wmv",".xls",".xlsx",".zip"], // 自定义可上传文件类型 
			      filemaxsize = 1024 * 5,   // 5M  限制最大上传文件为5兆 
			      obj_file = document.getElementById("NewFile"),
			      filepath = obj_file.value,
			      isnext = false,
			      Mfile = getFileName(filepath),
			      fileend = Mfile.substring(Mfile.length-4,Mfile.length).toLowerCase();
			  if (filepath) {
			       if (filetypes && filetypes.length > 0) {
				   for (var i = 0; i < filetypes.length; i++) {
					    if (filetypes[i] == fileend) {
							  isnext = true;
							  break;
						  }
					   }
				   }
				   if (!isnext) {
						alert("您好,暂且不接受上传此文件类型！");
						obj_file.focus();
						obj_file.value="";
						return false;
				   }
			   } else {
				   return false;
			   }

			   if(!isIE){  // IE 目前尚存在严重的兼容性问题,不做前端检测,若要检测需要配合flash插件SWFUpload
				   fileSize = obj_file.files[0].size;
				   size = fileSize / 1024;
				   if (size > filemaxsize) {
					   alert("附件大小不能大于" + filemaxsize / 1024 + "M！");
				       obj_file.focus();
					   obj_file.value="";
					   return false;
				   }
				   if (size <= 0) {
					  alert("附件大小不能为0M！");
					  obj_file.focus();
					  obj_file.value="";
					  return false;
				   }
			    }
				document.getElementById('return_error').innerHTML='上传中,请稍后...';
				document.Upload.submit();
			}   	
			function getFileName(path){
				var pos1 = path.lastIndexOf('/');
				var pos2 = path.lastIndexOf('\\\\');
				var pos  = Math.max(pos1, pos2)
				if( pos<0 ) {
					return path;
				}
				else {
					return path.substring(pos+1);
				}
			}
			function OnUploadCompleted( errorNumber, fileUrl, fileName, customMsg){
				document.getElementById('fileshow1').innerHTML="";
				var return_error=document.getElementById('return_error');
				document.Upload.NewFile.outerHTML=document.Upload.NewFile.outerHTML.replace(/(value=\\").+\\"/i,"\$1\\"");
				switch ( errorNumber ){
					case 0 :
						return_error.innerHTML='';
						break ;
					case 1 :
						return_error.innerHTML='<font color="red">'+customMsg+'</font>';
						return ;
					case 101 :
						return_error.innerHTML='<font color="blue">'+customMsg+'</font>';
						break ;
					case 201 :
						return_error.innerHTML='';
						break ;
					case 202 :
						return_error.innerHTML='<font color="red">无效的文件类型</font>';
						return ;
					case 203 :
						return_error.innerHTML='<font color="red">服务器连接失败,您可能没有权限.</font>';
						return ;
					case 500 :
						return_error.innerHTML='<font color="red">服务器连接失败</font>';
						break ;
					default :
						return_error.innerHTML='<font color="red">上传文件错误: '+errorNumber+'</font>';
						return ;
				}
				document.addform.apply_attach.value=fileUrl;
				showfile('sh');
			}
			function showfile(type){
				if (type=='sh') {
					var file=document.addform.apply_attach.value;
					if (file=="") {
						sh('fileup');
						hd('fileshow');
					}else{
						document.getElementById('fileshow').innerHTML='<a href="'+file+'" target="_blank" style="text-decoration:underline;color:blue;">'+file+'</a>　<a href="javascript:delfile();"><font color="red">删除</font></a>';
						hd('fileup');
						sh('fileshow');
					}
				}else{
					hd('fileup');
				}
			}
			function delfile(){
				var file=document.addform.apply_attach.value;
				\$.getJSON("/cgishell/golden/admin/manage/upload_ffpinfo.pl?callback=?", {User_ID:"$in{User_ID}",Serial_no:"$in{Serial_no}",Type:"delfile",keyword:file},
				function(data) {
					var catalog=data['delfile'];
					if (catalog=="删除成功") {
						document.getElementById('fileshow1').innerHTML="";
						document.addform.apply_attach.value="";
					}else{
						document.getElementById('fileshow1').innerHTML="*"+catalog;
					}
					showfile('sh');
					return;
				});
			}
			function sh(strtype)	{
				document.getElementById(strtype).style.display='inline';
			}
			function hd(strtype)	{
				document.getElementById(strtype).style.display='none';
			}
		</script>`;
	}
	## 查询Office信息	 dabin@2014-04-15
	my $office_list;
	$sql = "select distinct Office_ID from ctninfo..Corp_office where Corp_ID='$Corp_center' and Out_tkt in ('Z','W') and Status+''<>'N' and Office_type='A' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				my $sel;
				if ($row[0] eq $office_id) {	$sel = " selected";	}
				$office_list .= "<option value='$row[0]'$sel>$row[0]</option>\n";
			}
		}
	}
	#$depart,$class,$depart_y,$class_y,$d_num,$class,$dis,$d_num_y,$class_y,$dis_y
	## 航空公司舱位代码选择
	if ($in{air_code} eq "") {	$in{air_code}="CA";	}
	#and char_length(Class_code)=1
	$sql = "select distinct rtrim(Class_code),Discount from ctninfo..Class_agio
		where Airline_code='$in{air_code}'
			and End_date > getdate()
			and Start_date <= getdate()
			and Status='Y'
			and (Is_share <>'Y' or Is_share is null)
			and Corp_ID = 'SKYECH'
		order by Discount DESC ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				my $find_class='N';
				for ($i=0;$i<scalar(@c_code);$i++) {
					if ($c_code[$i] eq $row[0]) {
						$find_class='Y';
						$i=scalar(@c_code);
					}
				}
				if ($find_class eq "N") {
					push(@c_code,$row[0]);
					push(@c_dis,$row[1]);
					$o_seat = $row[0].$o_seat;
				}
			}
		}
	}
	## 舱位列表
	my $c_num = scalar(@c_code);
	for (my $f=0;$f<10 ;$f++) {
		if ($in{Type} eq "D" || $Sub_be{$f} ne "Y") {$class{$f} = $o_seat;	$class_y{$f} = $o_seat;}
		$o_min{$f}=$o_max{$f}=$o_min_y{$f}=$o_max_y{$f}="";
		if ($in{Type} eq "E" && $Sub_be{$f} eq "Y") {
			if ($class{$f} ne "") {
				$o_min{$f}=substr($class{$f},0,1);
				$o_max{$f}=substr($class{$f},length($class{$f})-1,length($class{$f}));
			}
			if ($class_y{$f} ne "") {
				$o_min_y{$f}=substr($class{$f},0,1);
				$o_max_y{$f}=substr($class{$f},length($class{$f})-1,length($class{$f}));
			}
		}
		for (my $i=0;$i<$c_num;$i++) {
			if (($in{Type} eq "E" && $o_min{$f} eq $c_code[$i] && $Sub_be{$f} eq "Y") || (($in{Type} eq "D" || ($in{Type} eq "E" && $Sub_be{$f} ne "Y")) && $i == $c_num - 1)) {
				$min_cls{$f} .="<option value='$c_code[$i]' selected>$c_code[$i] $c_dis[$i]</option>\n";
			}else{
				$min_cls{$f} .="<option value='$c_code[$i]'>$c_code[$i] $c_dis[$i]</option>\n";
			}
			if (($in{Type} eq "E" && $o_min_y eq $c_code[$i] && $Sub_be{$f} eq "Y") || (($in{Type} eq "D" || ($in{Type} eq "E" && $Sub_be{$f} ne "Y")) && $i == $c_num - 1)) {
				$min_cls_y{$f} .="<option value='$c_code[$i]' selected>$c_code[$i] $c_dis[$i]</option>\n";
			}else{
				$min_cls_y{$f} .="<option value='$c_code[$i]'>$c_code[$i] $c_dis[$i]</option>\n";
			}

			if ($o_max{$f} eq $c_code[$i]) {
				$max_cls{$f} .="<option value='$c_code[$i]' selected>$c_code[$i] $c_dis[$i]</option>\n";
			}else{
				$max_cls{$f} .="<option value='$c_code[$i]'>$c_code[$i] $c_dis[$i]</option>\n";
			}
			if ($o_max_y{$f} eq $c_code[$i]) {
				$max_cls_y{$f} .="<option value='$c_code[$i]' selected>$c_code[$i] $c_dis[$i]</option>\n";
			}else{
				$max_cls_y{$f} .="<option value='$c_code[$i]'>$c_code[$i] $c_dis[$i]</option>\n";
			}
		}
	}

	if ($in{Type} eq "E") {#fanzy@2012-9-12
		print qq!
		<script type="text/javascript" src="/admin/js/popwin.js"></script>
		<div id="append_parent"></div>!;
		$ffp_limit=qq!<tr bgcolor=ffffff ><td colspan=10 align=right ><input type="button" onclick="window.open('ffp_limit.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&air_code=$in{air_code}&air_ffp=$uri_ffp','更多限制')" value="更多限制" class="btn32"/></td></tr>!;
	}
	if(($tag_int&1)==1){
		$suspend="selected";
	}
	($ffp_ck,$reward_ck1,$reward_ck2,$reward_ck3,$yeah,$not)=();
	if(($tag_int&8)==8){	##二方协议
		$ffp_ck="selected";
	}
	if(($tag_int&2)==2 && ($tag_int&4)!=4){	##前返
		$reward_ck1="selected";
	}
	if(($tag_int&2)!=2 && ($tag_int&4)==4){	##后返
		$reward_ck2="selected";
	}
	if(($tag_int&2)==2 && ($tag_int&4)==4){	##前后返
		$reward_ck3="selected";
	}
#	if(($tag_int&16)==16){ ## sfc前自动做RMK IC指令
#		$yeah="selected";
#	}else {
#		$not="selected";
#	}
	
	print qq`
	<div class="wrapper">
		<dl><dt>$title_name</dt></dl>
	</div>
	$upfile_htm
	<form action="ffp_info.pl" method=post name="addform">
	<table width=100% align=center cellspacing="1" bgcolor="#C0C7D9">
		<tr bgcolor=ffffff>`;
			if ($in{Type} eq "E") {
				my $new_ffp=qq!<input type=text id=new_ffp name=new_ffp value="$in{air_ffp}" size=8 class="inputStyle">
						<input type=button class=btn33 value='修改协议号' onclick="check('chg');">!;
				print qq`
				<td height=25 align="right">航空公司：</td><td>$air_code<input type=hidden name=air_code id=air_code value="$in{air_code}"></td>
				<td align="right">三方协议号：</td><td>$new_ffp<input type=hidden name=air_ffp id='air_ffp' value="$in{air_ffp}"><input type=hidden name="apply_attach" value="$file_name"></td>`;
			}else{
				print qq`
				<td height=25 align="right">航空公司：</td><td><input type="text" name="air_code" id=air_code onchange="ch_acode();" style='width:140px;' onkeyup="this.value=this.value.toUpperCase();" value="$in{air_code}" cust_pin="right" cust_title="航司名称" rigor="rigor" cust_changes="ALL" custSug="0" ajax_url="/cgishell/golden/admin/manage/get_ffp.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Form_type=airlines"></td>
				<td align="right">三方协议号：</td><td><input type=text name=air_ffp id='air_ffp' class="inputStyle"><input type=hidden name="apply_attach" value=""></td>`;
			}
			print qq`
			<td align="right">OFFICE号：</td><td><select name=office_id style='width:110px;'>$office_list</select></td>
			<td align="right">客户名称：</td><td><input type=text name=comment size=16 value="$comment" class="inputStyle" ></td>
			</tr>
			<tr bgcolor=ffffff>
			<td align="right">任务量：</td><td><input type=text name=task_num size=6 value="$task_num" class="inputStyle" onKeypress="if (event.keyCode < 47 || event.keyCode > 57 || this.value.length>3) event.returnValue = false;"> 万/月</td>
			<td align="right">有效期限：</td>
				<td><input type=text name=Start_date id=sdate size=16 maxLength=10 value="$Start_date" class="inputStyle" onclick="event.cancelBubble=true;showCalendar('sdate',true,'sdate','','','','','','','','text','sdate');"></td>
			<td align="right">结束日期：</td><td><input type=text name=End_date id=edate size=16 maxLength=10 value="$End_date" class="inputStyle" onclick="event.cancelBubble=true;showCalendar('edate',true,'edate','','','','','','','','text','edate');"></td>
			<td align="right" >搭桥Office：</td><td><input type=text name=Ref_office1 id=Ref_office1 value="$Ref_office1" size=7 maxlength=6 />　<input type=text name=Ref_office2 id=Ref_office2 value="$Ref_office2" size=7 maxlength=6 /></td>
			</tr>
			<tr bgcolor=ffffff>
			<td align="right">协议类型：</td><td><select name='ffp_type' style='width:80px;'><option value=''>三方协议</option><option value='1' $ffp_ck>二方协议</option></select></td>
			<td align="right">奖励方案：</td><td><select name='reward_way' style='width:80px;'><option value='1' $reward_ck1>前返</option><option value='2' $reward_ck2>后返</option><option value='3' $reward_ck3>前后返</option></select></td>
			<td align="right">状态：</td><td><select name='Status' style='width:50px;'><option value=''>启用</option><option value='1' $suspend>暂停</option></select></td>`;
#			if ( $in{air_code} eq "CZ" ){
#				print qq `<td align="right">SFC前自动做RMK IC指令：</td><td><select name='auto_command' style='width:50px;'><option value='1' $yeah>是</option><option value='' $not>否</option></select></td>`;
#			}else {
			#}
			print qq`
				<td colspan=2></td></tr>
				<tr bgcolor=ffffff>
				<td align="right">核心备注：</td><td><input type=text name=coreNote id='coreNote' class="inputStyle" value="$core_note"></td>
				<td align="right">信息备注：</td><td><input type=text name=infoNote id='infoNote' class="inputStyle" value="$info_note"></td><td colspan=2></td><td colspan=2></td></tr>
			$ffp_limit
	</table>
	<br>
	<table width=100% align=center cellspacing="1" bgcolor="#EAEAEA">`;
		my $sub_num=0;
		for (my $f=0;$f<10 ;$f++) {
			my $Sub_style="style='display: none;'";
			if ($f==0 || $Sub_be{$f} eq "Y") {$Sub_style="";}
			if ($Sub_style eq "") {$sub_num++;}
			$depart{$f}=~ s/\s*//g;
			$arrive{$f}=~ s/\s*//g;
			$depart_y{$f}=~ s/\s*//g;
			$arrive_y{$f}=~ s/\s*//g;
			print qq`
			<tr id="Sub_$f" $Sub_style>
				<td>
					<table width=100% align=center cellspacing="1" bgcolor="#C0C7D9">
						<tr bgcolor=f0f0f0>
							<td height=25 colspan="4" align="center">国　　内</td>
							<td colspan="4" align="center">国　　际</td>
						</tr>
						<tr bgcolor=ffffff>
							<td height=25 align="right" bgcolor=f0f0f0>始发城市：</td>
							<td><input type=text name="depart_N$f" id="depart_N$f" size=20 value="$depart{$f}" class="inputStyle" title="多个用,分割"></td>
							<td align="right" bgcolor=f0f0f0>抵达城市：</td>
							<td><input type=text name="arrive_N$f" id="arrive_N$f" size=20 value="$arrive{$f}" class="inputStyle" title="多个用,分割"></td>
							<td align="right" bgcolor=f0f0f0>始发城市：</td>
							<td><input type=text name="depart_Y$f" id="depart_Y$f" size=20 value="$depart_y{$f}" class="inputStyle"title="多个用,分割"></td>
							<td align="right" bgcolor=f0f0f0>抵达城市：</td>
							<td><input type=text name="arrive_Y$f" id="arrive_Y$f" size=20 value="$arrive_y{$f}" class="inputStyle" title="多个用,分割"></td>
						</tr>
						<tr bgcolor=ffffff>
							<td height=25 align="right" bgcolor=f0f0f0>适用舱位：</td>
							<td colspan="3"><select name="Min_class$f" id="Min_class$f" style='width:70px;' onchange="ch_seat('$f');">$min_cls{$f}</select>-<select name="Max_class$f" id="Max_class$f" style='width:70px;' onchange="ch_seat('$f');">$max_cls{$f}</select>
								<input type=text name="class_N$f" size=20 class="inputStyle" value="$class{$f}">
								<br>定额代理费：<input type=text name="Comm_rate_N$f" id="Comm_rate_N$f" size=4 class="inputStyle" value="$Comm_rate_N{$f}">元</td>
							<td align="right" bgcolor=f0f0f0>适用舱位：</td>
							<td colspan="3"><select name="Min_class_Y$f" id="Min_class_Y$f" style='width:70px;' onchange="ch_seat_Y('$f');">$min_cls_y{$f}</select>-<select name="Max_class_Y$f" id="Max_class_Y$f" style='width:70px;' onchange="ch_seat_Y('$f');">$max_cls_y{$f}</select>
								<input type=text name="class_Y$f" id="class_Y$f" size=40 class="inputStyle" value="$class_y{$f}"></td>
						</tr>
						<tr bgcolor=ffffff>
							<td colspan="4" align="center" valign="top">
								<table width="100%" cellspacing="1" bgcolor="#C0C7D9">
									<tr align="center" bgcolor="#F0F0F0">
										<td height="20">舱位</td>
										<td>折扣率</td>
										<td>定额代理费</td>
									</tr>`;
									if ($d_num{$f} eq "") {$d_num{$f}=0;}
									if ($in{Type} eq "E" && $Sub_be{$f} eq "Y") {
										for (my $i=0;$i<$d_num{$f};$i++) {
											my $c_style="";
											my $cls_list="";
											for (my $j=0;$j<scalar(@c_code);$j++) {
												if ($dclass[$i]{$f} eq $c_code[$j]) {
													$cls_list .="<option value='$c_code[$j]' selected>$c_code[$j] $c_dis[$j]</option>\n";
												}else{
													$cls_list .="<option value='$c_code[$j]'>$c_code[$j] $c_dis[$j]</option>\n";
												}
											}
											print qq`
											<tr align="center" bgcolor="#FFFFFF" id="seat_N_$i\sub$f" $c_style>
												<td height="20">
													<select name="class_N_$i\sub$f" style='width:70px;'>$cls_list</select>
												</td>
												<td>
													<input type="text" name="dis_N_$i\sub$f" size="4" maxlength="4" value="$dis[$i]{$f}" class="inputStyle" onblur="checkFloat(this);"/>
												</td>
												<td>
													<input type="text" name="agt_N_$i\sub$f" size="5" maxlength="5" value="$agt[$i]{$f}" class="inputStyle" />元
												</td>
											</tr>`;
										}
									}
									##caizd@2013-08-19 增加可维护舱位数量
									for (my $i=$d_num{$f};$i<$c_num;$i++) {
										my $c_style="style='display: none;'";
										print qq`
										<tr align="center" bgcolor="#FFFFFF" id="seat_N_$i\sub$f" $c_style >
											<td height="20">
												<select name="class_N_$i\sub$f" style='width:70px;'>$min_cls{$f}</select>
											</td>
											<td>
												<input type="text" name="dis_N_$i\sub$f" size="4" maxlength="4" class="inputStyle" onblur="checkFloat(this);"/>
											</td>
											<td>
												<input type="text" name="agt_N_$i\sub$f" size="5" maxlength="5" value="0" class="inputStyle" />元
											</td>
										</tr>`;
									}
									print qq`
									<tr align="center" bgcolor="#FFFFFF">
										<td colspan="3" align="right">
											<input type="hidden" name="seatnum_N$f" id="seatnum_N$f" value="$d_num{$f}" />
											<input type="hidden" name="seatsum_N$f" id="seatsum_N$f" value="$c_num" />
											<input type="button" value=" 增 加 " class="btn32" onclick="javascript:update_seat('add','N','$f');" />
											<input type="button" value=" 减 少 " class="btn32" onclick="javascript:update_seat('del','N','$f');" />
										</td>
									</tr>
								</table>
							</td>
							<td colspan="4" align="center" valign="top">
								<table width="100%" cellspacing="1" bgcolor="#C0C7D9">
									<tr align="center" bgcolor="#F0F0F0">
										<td height="20">舱位</td>
										<td>折扣率</td>
										<td>定额代理费</td>
									</tr>`;
									if ($d_num_y{$f} eq "") {$d_num_y{$f}=0;}
									if ($in{Type} eq "E" && $Sub_be{$f} eq "Y") {
										for (my $i=0;$i<$d_num_y{$f};$i++) {
											my $c_style="";
											my $cls_list="";
											for (my $j=0;$j<scalar(@c_code);$j++) {
												if ($dclass_y[$i]{$f} eq $c_code[$j]) {
													$cls_list .="<option value='$c_code[$j]' selected>$c_code[$j] $c_dis[$j]</option>\n";
												}else{
													$cls_list .="<option value='$c_code[$j]'>$c_code[$j] $c_dis[$j]</option>\n";
												}
											}
											print qq`
											<tr align="center" bgcolor="#FFFFFF" id="seat_Y_$i\sub$f" $c_style >
												<td height="20">
													<select name="class_Y_$i\sub$f" style='width:70px;'>$cls_list</select>
												</td>
												<td>
													<input type="text" name="dis_Y_$i\sub$f" size="4" maxlength="4" value="$dis_y[$i]{$f}" class="inputStyle" onblur="checkFloat(this);"/>
												</td>
												<td>
													<input type="text" name="agt_Y_$i\sub$f" size="5" maxlength="5" value="$agt_y[$i]{$f}" class="inputStyle" />元
												</td>
											</tr>`;
										}
									}
									##caizd@2013-08-19 增加可维护舱位数量
									for (my $i=$d_num_y{$f};$i<$c_num;$i++) {
										my $c_style="style='display: none;'";
										print qq`
										<tr align="center" bgcolor="#FFFFFF" id="seat_Y_$i\sub$f" $c_style >
											<td height="20">
												<select name="class_Y_$i\sub$f" style='width:70px;'>$min_cls{$f}</select>
											</td>
											<td>
												<input type="text" name="dis_Y_$i\sub$f" size="4" maxlength="4" class="inputStyle" onblur="checkFloat(this);" />
											</td>
											<td>
												<input type="text" name="agt_Y_$i\sub$f" size="5" maxlength="5" value="0" class="inputStyle" />元
											</td>
										</tr>`;
									}
									print qq`
									<tr align="center" bgcolor="#FFFFFF">
										<td colspan="6" align="right">
											<input type="hidden" name="seatnum_Y$f" id="seatnum_Y$f" value="$d_num_y{$f}" />
											<input type="hidden" name="seatsum_Y$f" id="seatsum_Y$f" value="$c_num" />
											<input type="button" value=" 增 加 " class="btn32" onclick="javascript:update_seat('add','Y','$f');" />
											<input type="button" value=" 减 少 " class="btn32" onclick="javascript:update_seat('del','Y','$f');" />
										</td>
									</tr>
								</table>
							</td>
						</tr>
					</table>
				</td>
			</tr>`;
		}
		print qq`
		<tr bgcolor=ffffff align=center>
			<td bgcolor=white>
				<input type="button" value=" 增 加 " class="btn30" onclick="javascript:sub_seat('add');" />
				<input type="button" value=" 减 少 " class="btn30" onclick="javascript:sub_seat('del');" />
			</td>
		</tr>
		</table>
		<br>
		<div align=center>
			<input type=button value=' $op_name ' onclick="check('');" class=btn20>
			<input type=hidden name=User_ID value='$in{User_ID}'>
			<input type=hidden name=Serial_no value='$in{Serial_no}'>
			<input type=hidden name=Type value='$in{Type}'>
			<input type=hidden name=action value='add'>
			<input type=hidden name=sub_num id="sub_num"  value='$sub_num' >
		</div>
	</form>
	
	<script language='javascript'>
		Array.prototype.unique = function () {
			var temp = new Array();
			this.sort();
			for(i = 0; i < this.length; i++) {
				if( this[i] == this[i+1]) {
					continue;
				}
				temp[temp.length]=this[i];
			}
			return temp;
		}
		function check(type) {
			var air_ffp=document.getElementById("air_ffp").value;
			if(document.getElementById("new_ffp")){
				air_ffp=document.getElementById("new_ffp").value;
			}
			if (document.getElementById("air_code").value=='') {
				alert("请输入航空公司！！");
				return;
			}
			if (air_ffp=='') {
				alert("请输入三方协议号！！");
				return;
			}
			var b = /^[0-9a-zA-Z]*\$/g;
			if (!b.test(air_ffp)) {
				alert("三方协议号包含特殊字符！！");
				return;
			}
			var sub_num = document.getElementById("sub_num").value;
			var departN=[];
			var departY=[];
			for (var f=0;f<sub_num ;f++) {
				var depart_N=document.getElementById("depart_N"+f).value;
				var depart_Y=document.getElementById("depart_Y"+f).value;
				var arrive_N=document.getElementById("arrive_N"+f).value;
				var arrive_Y=document.getElementById("arrive_Y"+f).value;
				depart_N.replace(/(^\s*)|(\s*\$)/g, "");
				depart_Y.replace(/(^\s*)|(\s*\$)/g, "");
				arrive_N.replace(/(^\s*)|(\s*\$)/g, "");
				arrive_Y.replace(/(^\s*)|(\s*\$)/g, "");
				if (sub_num>1 && 1==2) {//取消限制 
					if (depart_N=="" && arrive_N=="") {
						alert("如果要发布多条国内始发城市段，请确认始发城市不能为空！！");
						document.getElementById("depart_N"+f).focus();
						return;
					}
					if (depart_Y=="" && arrive_Y=="") {
						alert("如果要发布多条国际始发城市段，请确认始发城市不能为空！！");
						document.getElementById("depart_Y"+f).focus();
						return;
					}
				}
				var departtmpN=depart_N.split(",");
				var departtmpY=depart_Y.split(",");
				var arrivetmpN=arrive_N.split(",");
				var arrivetmpY=arrive_Y.split(",");
				for (var t=0;t<departtmpN.length ;t++) {
					for (var a=0;a<arrivetmpN.length ;a++) {
						departN.push(departtmpN[t]+"|"+arrivetmpN[a]);
					}
				}
				for (var t=0;t<departtmpY.length ;t++) {
					for (var a=0;a<arrivetmpY.length ;a++) {
						departY.push(departtmpY[t]+"|"+arrivetmpY[a]);
					}
				}
			}
			if (departN.length!=departN.unique().length) {
				alert("请确认国内航段是否有重复！！");
				return;
			}
			if (departY.length!=departY.unique().length) {
				alert("请确认国际航段是否有重复！！");
				return;
			}
			if (type \!= '') {
				document.addform.action.value=type;
			}
			document.addform.submit();
		}
		function sub_seat(op){
			var sub_num = document.getElementById("sub_num").value;
			if (op == 'add') {
				if (sub_num < 10) {
					for (var f=0;f<10 ;f++) {
						if (f>sub_num) {
							document.getElementById("Sub_" +f).style.display = "none";
						}else{
							document.getElementById("Sub_" +f).style.display = "";
						}
					}
					sub_num++;
					document.getElementById("sub_num").value = sub_num;
				}
			}
			else {
				if (sub_num > 1) {
					sub_num--;
					for (var f=0;f<10 ;f++) {
						if (f>=sub_num) {
							document.getElementById("Sub_" +f).style.display = "none";
						}else{
							document.getElementById("Sub_" +f).style.display = "";
						}
					}
					document.getElementById("sub_num").value = sub_num;
				}
			}
		}
		function update_seat(op,type,subid){
			var c_num = document.getElementById("seatnum_"+type+subid).value;
			var seatsum=parseInt(document.getElementById("seatsum_"+type+subid).value,10);
			if (op == 'add') {
				if (c_num < seatsum) {
					document.getElementById("seat_" +type+"_"+ c_num+"sub"+subid).style.display = "";
					c_num++;
					document.getElementById("seatnum_"+type+subid).value = c_num;
				}
			}
			else {
				if (c_num > 0) {
					c_num--;
					document.getElementById("seat_" +type+"_"+ c_num+"sub"+subid).style.display = "none";
					document.getElementById("seatnum_"+type+subid).value = c_num;
				}
			}
		}
		function ch_seat(subid){
			var i_min = document.getElementById("Min_class"+subid).selectedIndex;
			var i_max = document.getElementById("Max_class"+subid).selectedIndex;
			if (i_min < i_max) {
				alert('对不起，请注意舱位选择顺序');
				return;
			}
			var s_seat='';
			for (var i=i_min;i>=i_max;i--) {
				s_seat = s_seat + document.getElementById("Min_class"+subid).options[i].value;
			}
			document.getElementById("class_N"+subid).value=s_seat;
		}
		function ch_seat_Y(subid){
			var i_min = document.getElementById("Min_class_Y"+subid).selectedIndex;
			var i_max = document.getElementById("Max_class_Y"+subid).selectedIndex;
			if (i_min < i_max) {
				alert('对不起，请注意舱位选择顺序');
				return;
			}
			var s_seat='';
			for (var i=i_min;i>=i_max;i--) {
				s_seat = s_seat + document.getElementById("Min_class_Y"+subid).options[i].value;
			}
			document.getElementById("class_Y"+subid).value=s_seat;
		}
		function ch_acode(){
			var acode = document.getElementById("air_code").value;
			window.location.href='ffp_info.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Type=$in{Type}&air_code='+acode+'&air_ffp=$uri_ffp';
		}
		function checkFloat(obj){
			if (!/^\s*\$/.test(obj.value)) {
				if (isNaN(obj.value)) {
					alert("格式错误，请输入大于0小于等于1的两位小数！");
					obj.value = "";
					obj.focus();
				}
				else{
					if (parseFloat(obj.value) > 1 || parseFloat(obj.value) <= 0) {
						obj.value = "";
						alert("输入错误，请输入大于0小于等于1的两位小数！");
						obj.focus();
					}
					else{
						if (obj.value.indexOf('.') != -1) {
							if (obj.value.substring(obj.value.indexOf('.'), obj.value.length).length > 3) {
								obj.value = obj.value.substring(0, obj.value.indexOf('.') + 3);
							}
						}
					}
				}
			}
		}
	</script>`;
}
elsif ($in{Type} eq "B") {
	my $a_list="<option value=''>-- 请选择航空公司 --</option>";
	my $a_temp=$ffp_info="";
	$sql = "select a.Airline_code,a.Air_ffp,b.Airline_cname from ctninfo..Ffp_info a,ctninfo..Airlines b
		where a.Airline_code=b.Airline_code and a.Sales_ID='$Corp_center' and a.Airline_code in('$in{air_code}')
		 and (a.End_date>=getdate() or a.End_date is null) and (a.Start_date<=getdate() or a.Start_date is null) ";
	#print "<pre>$sql";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				if ($a_temp ne $row[0]) {
					if ($a_temp eq "") {	$ffp_info .= "[";				}
					else{	$ffp_info=substr($ffp_info,0,length($ffp_info)-1);		$ffp_info .= "],[";		}
					$a_temp = $row[0];
					if ($row[0] eq $in{air_code}) {
						$a_list .= "<option value='$row[0]' selected >$row[0] $row[2]</option>\n";
					}
					else{
						$a_list .= "<option value='$row[0]'>$row[0] $row[2]</option>\n";
					}
				}
				$ffp_info .= qq!"$row[1]",!;
			}
		}
	}
	if ($ffp_info ne "") {
		$ffp_info=substr($ffp_info,0,length($ffp_info)-1);		$ffp_info .= "]";
	}
	##chengzx 增加下载功能
	print qq`
	<div class="wrapper">
		<dl><dt>查询旅客信息</dt></dl>
	</div>
	<form action="ffp_info.pl" method="post" name="query">
	<table cellspacing="1" bgcolor="#C0C7D9" width="100%" align=center>
		<tr bgcolor=f0f0f0><td>
			<table border=0 cellpadding=0 cellspacing=1 width=100%>
				 <tr>
					<td height=25><b>航空公司：</b></td>
					<td><select name=air_code style='width:140px;' onChange="get_ffp('query')">$a_list</select></td>
					<td><b>三方协议号：</b></td>
					<td><select name="air_ffp"><option value="">三方协议号</option></select></td>
					<td><b>证件号：</b></td>
					<td><input type=text name=card_id size=18 value="$in{card_id}" class="inputStyle" onKeypress="if (event.keyCode < 45 || event.keyCode > 57) event.returnValue = false;"></td>
					<td><b>姓名：</b></td>
					<td><input type=text name=user_name size=18 value="$in{user_name}" class="inputStyle"></td>
					<td><b>维护日期：</b></td>
					<td><input type=text name=op_sdate id=sdate size=10 class="inputStyle" value="$in{op_sdate}" onclick="event.cancelBubble=true;showCalendar('sdate',true,'sdate','','','','','','','','text','sdate');"> - <input type=text name=op_edate id=edate size=10 value="$in{op_edate}" class="inputStyle" onclick="event.cancelBubble=true;showCalendar('edate',true,'edate','','','','','','','','text','edate');"><font color=brown>(不包含)</font></td>
					<td align=center>
						<input type=hidden name=User_ID value='$in{User_ID}'>
						<input type=hidden name=Serial_no value='$in{Serial_no}'>
						<input type=hidden name=Type value='$in{Type}'>
						<input type=submit value=' 查 询 ' class=btn30>
					</td>
				 </tr>
			 </table>
		</td></tr>
	</table>
	</form>
	<br>
	<form action="ffp_info.pl" method="post" name="modform">
	<table width=100% align=center cellspacing="1" bgcolor="#C0C7D9">
		<tr>
			<td bgcolor=white colspan=6 align=right>
			<a href="http://$G_SERVER/cgishell/golden/admin/manage/ffp_info_down.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&air_ffp=$uri_ffp&air_code=$in{air_code}&op_sdate=$in{op_sdate}&op_edate=$in{op_edate}" title='下载' ><img src='/admin/images/download2.gif' border=0 align=absmiddle>下载数据</a>
			</td>
		</tr>
		<tr bgcolor=f0f0f0 align=center>
			<td width=60 height=20><input type=Checkbox name=cball onclick='javascript:select_all();' >全选</td><td>航空公司</td><td>三方协议号</td><td>证件号码</td><td>姓名</td><td>操作</td>
		</tr>`;
		$where = " from ctninfo..Ffp_card where Sales_ID = '$Corp_center' \n";
		if ($in{air_code} ne "") {	$where .= " and Airline_code='$in{air_code}' \n";		}
		if ($in{air_ffp} ne "") {	$where .= " and Air_ffp='$in{air_ffp}' \n";		}
		if ($in{card_id} ne "") {	$where .= " and Card_ID='$in{card_id}' \n";		}
		if ($in{user_name} ne "") {	$where .= " and User_name='$in{user_name}' \n";		}
		if ($in{op_sdate} ne "") {	$where .= " and Op_time>='$in{op_sdate}' \n";}
		if ($in{op_edate} ne "") {	$where .= " and Op_time<'$in{op_edate}' \n";}
		$sql = "select count(*) ".$where;
		$Total_num=&Exec_sql();

		## 生成查询游标
		my $records = $in{perpage} eq '' ? 20 : $in{perpage};
		$Start = $in{Start};
		if($in{Start} eq "" || $in{Start} eq " ") { $Start=1; }
		my $t_records = $records*$Start;
		$sql = " select top $t_records Serial_id,Airline_code,Air_ffp,rtrim(Card_ID),Comment,User_ID,convert(char(10),Op_time,102)+''+convert(char(8),Op_time,108),rtrim(User_name) \n";
		$sql .= $where;
		$sql .= " order by Airline_code,Air_ffp,Card_ID \n";
		#print "<pre>$sql";
		$Find_res = 1;
		my $i_num = 0;
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					if($Find_res<=$Start*$records && $Find_res>($Start-1)*$records ){
						my $uri_ffp_d=&uri_escape($row[2]);
						print qq!
						<tr bgcolor=fff0f0 title='操作人：$row[5] 操作时间：$row[6]' style='cursor:pointer;'>
							<td height=20><input type=Checkbox name="cb_$i_num" value='Y'></td>
							<td>$air_code{$row[1]}<input type=hidden name="s_id_$i_num" value="$row[0]" ></td>
							<td>$row[2]<input type=hidden name="air_ffp" value="$row[2]" ></td>
							<td>$row[3]<input type=hidden name="air_code" value="$row[1]" ></td>
							<td>$row[7]</td>
							<td align=center><a href="javascript:mod_card('$row[0]','$row[1]','$row[2]','$row[3]','$row[7]');" title='修改'>修改</a>
								<a href="javascript:if(confirm('确定要删除此旅客信息吗?'))location='ffp_info.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Type=$in{Type}&action=del&s_id=$row[0]&air_code=$row[1]&air_ffp=$uri_ffp_d'" title='删除'>删除</a>
							</td>
						</tr>!;
						$i_num++;
					}
					$Find_res ++;
				}
			}
		}

		if ($Total_num == 0) {
			print qq`<tr bgcolor=f0f0f0><td height=20 colspan='6'><font color=red>对不起，没有找到相关记录！</font></td></tr>`;
		}
		else{
			my $pageButtons = &showPages($Total_num, $records, $Start, 10, '', 1);
			print qq`
			<tr bgcolor=f0f0f0>
				<td height=20><input type=submit value='批量删除' class="btn30"></td>
				<td height=20><input type=hidden name="del_all" id="del_all" value='' class="btn30"><input type=submit value='删除全部' onclick="document.getElementById('del_all').value='Y';" class="btn30"></td>
				<td colspan='5'>
					<div style="clear: both; padding: 5px 0;">
						$pageButtons
					</div>
				</td>
			</tr>`;
		}

	print qq`
	</table>
		<input type=hidden name=User_ID value='$in{User_ID}'>
		<input type=hidden name=Serial_no value='$in{Serial_no}'>
		<input type=hidden name=Type value='$in{Type}'>
		<input type=hidden name=ffp_for_del value='$in{air_ffp}'>
		<input type=hidden name=aircode_for_del value='$in{air_code}'>
		<input type=hidden name=action value='del'>
		<input type=hidden name=i_num value='$i_num'>
	</form>
	<br><br>
	<div class="wrapper">
		<dl><dt>增加旅客信息</dt></dl>
	</div>
	<form action="ffp_info.pl" method=post name="addform">
	<table width=100% align=center cellspacing="1" bgcolor="#C0C7D9">
		<tr bgcolor=f0f0f0>
			<td height=25>航空公司：<select name=air_code style='width:140px;' onChange="get_ffp('addform')" id=air_code>$a_list</select></td>
			<td>三方协议号：<select name="air_ffp" id='air_ffp'><option value="">三方协议号</option></select></td>
			<td>证件号码：<input type=text name=card_id size=18 class="inputStyle" onKeypress="if (event.keyCode < 45 || event.keyCode > 57) event.returnValue = false;"></td>
			<td>姓名：<input type=text name=user_name size=18 class="inputStyle"></td>
			<td align=center><input type=hidden name=User_ID value='$in{User_ID}'>
				<input type=hidden name=Serial_no value='$in{Serial_no}'>
				<input type=hidden name=Type value='$in{Type}'>
				<input type=hidden name=action value='add'>
				<input type=hidden name=s_id value=''>
				<input type=button value=' 提 交 ' onclick='check_card();' class=btn30>
			</td>
		</tr>
	</table>
	</form>`;

	print qq`<br><br>
	<div class="wrapper">
		<dl><dt>上传旅客信息</dt></dl>
	</div>

	<dd>
	<form action="http://$G_SERVER/cgishell/golden/admin/manage/ffp_up.pl" method="post" name="upload" ENCTYPE="multipart/form-data">
		<table width=100% align=center cellspacing="1" bgcolor="#C0C7D9">
			<tr align=center bgcolor=f0f0f0>
				<td height=22>文件：<input type="file" name="upfile" size="30" class="inputStyle"></td>
				<td><input type="button" value="上传Excel" onclick="check_excel();" class="btn30" onmouseover="this.className='btn31'" onmouseout="this.className='btn30'" /></td>
				<td><a href='http://www.skyecho.com/download/up_ffp_card.xls'>下载模板</a>
					<input type="hidden" name="User_ID" value="$in{User_ID}" />
					<input type="hidden" name="Serial_no" value="$in{Serial_no}" />
				</td>
			</tr>
		</table>
	</form>
	</dd>
	<script type="text/javascript" src="/admin/js/ajax/jquery-1.3.2.min.js" charset="gb2312"></script>;
	<script>
	function select_all(){
		var num=$i_num;
		var i;
		for (i=0;i<num ;i++) {
			var tt
			tt=eval('document.modform.cb_'+i);
			tt.checked = document.modform.cball.checked;
		}
	}
	function check_card() {
		if (document.addform.air_code.value=='') {
			alert("请输入航空公司！！");
			return;
		}
		if (document.getElementById("air_ffp").value=='') {
			alert("请输入三方协议号！！");
			return;
		}
		if (document.addform.card_id.value=='' && document.addform.user_name.value=='') {
			alert("请输入证件号码或姓名！！");
			return;
		}
		//if (document.addform.card_id.value!=''){
		//	if (document.addform.card_id.value.length ==15 || document.addform.card_id.value.length==18) {
		//	}else{
		//		alert("请保持证件号码的长度为15位或18位！！");
		//		return;
		//	}
		//}
		
			var card_id = document.addform.card_id.value;
			var air_code = document.addform.air_code.value;
			\$.ajax({type:"POST",
						url:"ffp_info.pl?callback=?",
						dataType:'jsonp',
						data:{CardId:card_id,AirCode:air_code,User_ID:"$in{User_ID}",Serial_no:"$in{Serial_no}",action:"Q"},
						success:function(data){
							if(data["be_bound"] == 0){
								document.addform.submit();
							}else{
								var msg = "该客户已经绑定了"+data["be_bound"]+"个，请问是否继续绑定？";
								var r = confirm(msg);
								if(r==true){
										document.addform.submit();
								}else{
										
								}
							}	
						},
						error: function(XMLHttpRequest, textStatus, errorThrown){
								aler("connect error");
						}
					});

	}
	function mod_card(sid,air_code,air_ffp,card_id,user_name){
		document.addform.s_id.value=sid;
		document.addform.air_code.value=air_code;
		get_ffp('addform');
		document.getElementById("air_ffp").value=air_ffp;
		document.addform.card_id.value=card_id;
		document.addform.user_name.value=user_name;
		document.addform.action.value='mod';
	}
	var city = [$ffp_info];
	function get_ffp(formid){
		//获得航空公司和三方协议号下拉列表框的引用
		var sltProvince=document.forms[formid].elements["air_code"];
		var sltCity=document.forms[formid].elements["air_ffp"];
		var sProvinceIndex = sltProvince.selectedIndex;

		//将三方协议号下拉列表框清空，仅有第一个提示选项
		sltCity.length=1;
		if(sProvinceIndex>0){ //选择非 请选择你所在的航空公司时才读取对应的三方协议号
			//得到对应航空公司的城市列表数组
			if(city.length>0){
				var provinceCity=city[sProvinceIndex -1];
				//将相应航空公司的三方协议号填充到三方协议号选择框中
				for(var i=0;i<provinceCity.length;i++){
					//创建新的Option对象并将其添加到三方协议号下拉列表框中
					sltCity[i+1]=new Option(provinceCity[i],provinceCity[i]);
				}
			}
		 }
	}
	get_ffp('query');
	get_ffp('addform');
	document.getElementById("air_ffp").value='$in{air_ffp}';
	function check_excel(){
		var upfile = document.all.upfile.value;
		var pos = upfile.lastIndexOf(".");
		var lastname = upfile.substring(pos,upfile.length)  //此处文件后缀名也可用数组方式获得upfile.split(".")
		if (upfile == ''){
			alert("请选择文件上传！");
			document.upload.upfile.focus();
			return false;
		}
		else if (lastname.toLowerCase()!=".xls"){
			alert("您上传的文件类型为"+lastname+"，表格数据必须为.xls类型！");
			document.upload.upfile.focus();
			return false;
		}
		else{
			document.upload.submit();
		}
	}
	</script>`;
}
if($in{Type} eq "F"){#资料收集
	print qq!
	<link rel="stylesheet" type="text/css" href="/admin/style/multiSelect.css" />
	<script type="text/javascript" src="/admin/JS/jquery.js"></script>
	<script type="text/javascript" src="/admin/js/multiselectSrc/jquery.ui.core.js"></script>
	<script type="text/javascript" src="/admin/js/multiselectSrc/jquery.ui.widget.js"></script>
	<script type="text/javascript" src="/admin/js/multiselectSrc/jquery.multiselect.js"></script>
	<script type="text/javascript" src="/admin/js/multiselectSrc/comment_multselect.js"></script>
	<script type="text/javascript" >
		\$(function(){
			\$("#Ticket_type").multiselect({
				noneSelectedText: "==请选择==",
				checkAllText: "全选",
				uncheckAllText: "不全选",
				selectedList: 3
			});
			valuestr=getCookie('ac');
			setValues("Ticket_type",valuestr);
		})

	</script>!;
	my $air_times="<select name='air_times'>";
	for(my $i=1; $i<=10; $i++){
		if($in{air_times} == $i){
			$air_times .= "<option value='$i' selected>$i</option>";
		}
		else{
			$air_times .= "<option value='$i'>$i</option>";
		}
	}
	$air_times .= "</select>";
	my $today = &cctime(time);
	my ($week,$month,$day,$time,$year) = split(" ",$today);
	if($day<10){$day="0".$day;}
	$today = $year.".".$month."."."$day";
	if($in{Start_date} eq ""){
		$in{Start_date} = "$year.$month.01";
	}
	if($in{End_date} eq ""){
		$in{End_date} = &Nextdate($today);
	}
	if($in{air_type} eq "") { $in{air_type}='N'; }
	if($in{air_type} eq "N"){ $air_n="selected"; }
	elsif($in{air_type} eq "Y"){ $air_y="selected"; }
	if($in{date_type} eq "TKT"){ $date_tkt="selected"; }
	if($in{showis_A} eq "Y"){ $showis_A="checked"; }
	if($in{showis_B} eq "Y"){ $showis_B="checked"; }
	if($in{showis_C} eq "Y"){ $showis_C="checked"; }
	my $tkt_type=&get_dict($Corp_center,3,"","list");
	print qq`<div class="wrapper"><dl><dt>收集符合三方协议条件的旅客资料</dt></dl></div>
	<table cellspacing="1" bgcolor="#C0C7D9" width=100% align=center>
		<form action="ffp_info.pl" method="post" name="query">
		<tr bgcolor=f0f0f0><td>
			<table border=0 cellpadding=0 cellspacing=1 width=100%>
				 <tr>
					<td height=25><b>航空公司:</b><input type="text" name="air_code"  onkeyup="this.value=this.value.toUpperCase();" style="width:20px;" value="$in{air_code}" cust_pin="right" cust_title="航司名称" rigor="rigor" cust_changes="ALL" custSug="0" ajax_url="/cgishell/golden/admin/manage/get_ffp.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Form_type=airlines"></td>
					<td>
						<select name="date_type" id="date_type"><option value='AIR'>起飞日期</option><option value='TKT' $date_tkt>出票日期</option></select>：
						<input type=text name=Start_date id=sdate size=10 maxLength=10 value="$in{Start_date}" class="inputStyle" onclick="event.cancelBubble=true;showCalendar('sdate',true,'sdate','','','','','','','','text','sdate');"> -
						<input type=text name=End_date id=edate size=10 maxLength=10 value="$in{End_date}" class="inputStyle" onclick="event.cancelBubble=true;showCalendar('edate',true,'edate','','','','','','','','text','edate');">
					</td>
					<td><b>类型:</b>
						<select name="air_type"><option value='ALL'>全部</option><option value='N' $air_n>国内</option><option value='Y' $air_y>国际</option></select>
					</td>
					<td><b>三方协议号:</b><input type='text' name='ffp_id' size='13' maxLength=13 value='$in{ffp_id}' /></td>
					<td><b>统计粒度:</b>
						<label><input type=checkbox name=showis_A value="Y" $showis_A/>会员</label>
						<label><input type=checkbox name=showis_B value="Y" $showis_B/>客户</label>
						<label><input type=checkbox name=showis_C value="Y" $showis_C/>客户级别</label>
					</td>
					
				</tr>
				<tr>
					<td>
						<b>票证类型:</b><select onchange="selects('Ticket_type','Ticket_type_value')" style="width:150px;"  id='Ticket_type' multiple="multiple" size="6">$tkt_type</select>
					</td>
					<td>搭乘次数>=$air_times</td>
					<td colspan="2"><label for='is_down'><input type=checkbox name=is_down id=is_down value="Y" $ck_is_down /><b>下载报表</label></td>
					<td>
						<input type=hidden name=User_ID value='$in{User_ID}'>
						<input type=hidden name=Serial_no value='$in{Serial_no}'>
						<input type=hidden name=Type value='$in{Type}'>
						<input type=hidden name=Query value='Y'>
						<input type="hidden" name="Ticket_type" id="Ticket_type_value" value="$in{Ticket_type}" />
						<input type=submit value=' 统 计 ' class=btn30>
					</td>
				</tr>
			</table>
		</td></tr>
	</table>
	</form>`;
	if($in{Query} eq "Y"){
		my $has_query_server=&Has_query_server();
		if($has_query_server eq "Y"){
			$db=connect_database_query();
		}
		my $sql="select datediff(mm,'$in{Start_date}','$in{End_date}'),datepart(hour,getdate())";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					($month_diff,$cur_time)=@row;
				}
			}
		}
		if($month_diff>2 && $has_query_server ne "Y" && $cur_time>=7 && $cur_time<=18){
			print "<font color='red'>查询时段超过2个月,请在工作时段(07:00~18:00)之外执行！</font></body></html>";
			exit;
		}
		print qq`<table width=100% align=center cellspacing="1" bgcolor="#C0C7D9">
		<tr bgcolor=f0f0f0 align=center>
			<td>序号</td>
			<td>航司</td>
			<td height=20>旅客姓名</td>
			<td>证件号码</td>
			<td>搭乘次数</td>`;
			if ($in{showis_A} eq "Y") {print "<td>会员</td>";}
			if ($in{showis_B} eq "Y") {print "<td>客户</td>";}
			if ($in{showis_C} eq "Y") {print "<td>客户级别</td>";}
		print qq`</tr>`;
		if($in{date_type} eq "TKT") { 
			$date_type="a.Ticket_time";
			$tkt_index=" (index in_tkt_time)";
		}
		else{
			$date_type="l.Air_date";
			$air_index=" (index in_abk_adate)";
		}
		if ($in{air_code} eq "") {$in{air_code}="%";}
		my ($id,$id_book,$id_where,$id_group)=(",''");
		if ($in{showis_A} eq "Y") {
			$id=",case when u.User_type='C' then a.User_ID else '非会员' end";
			$id_book=",ctninfo..User_info u";
			$id_where=" and a.User_ID=u.User_ID and a.Sales_ID=u.Corp_num";
			$id_group=$id;
		}
		my ($cid,$cid_group)=(",''");
		if ($in{showis_B} eq "Y") {
			$cid=",a.Corp_ID";
			$cid_group=$cid;
		}
		my ($level,$level_book,$level_where,$level_group)=(",''");
		if ($in{showis_C} eq "Y") {
			$level=",case when isnull(c.Corp_level,'')<>'' then c.Corp_level else '未分级别' end ";
			$level_book=",ctninfo..Corp_info c";
			$level_where=" and a.Corp_ID=c.Corp_ID and a.Sales_ID=c.Corp_num";
			$level_group=$level;
		}
		my $ticket_where="";
		$in{Ticket_type}=~ s/\s*//g;
		if ($in{Ticket_type} ne "") {
			$in{Ticket_type}=~s/,/','/g;
			$ticket_str="'".$in{Ticket_type}."'";
			$ticket_where=" and d.Is_ET in($ticket_str)";
		}
		my $sql=qq`select case when '%'='$in{air_code}' then 'ALL' else l.Airline_ID end,d.First_name,d.Card_ID,count(*)$id$cid$level
				from ctninfo..Airbook_lines_$Top_corp l $air_index,ctninfo..Airbook_detail_$Top_corp d,ctninfo..Airbook_$Top_corp a $tkt_index
				$id_book
				$level_book
				where l.Reservation_ID=d.Reservation_ID and l.Res_serial=d.Res_serial
				and a.Reservation_ID=d.Reservation_ID and a.Reservation_ID=l.Reservation_ID
				and  $date_type>='$in{Start_date}' and $date_type<='$in{End_date}'
				and d.Dept_ID=0 and a.Alert_status='0' and a.Book_status in ('P','S','H')
				and datalength(d.Card_ID)>=4
				$ticket_where
				$id_where
				$level_where
				`;
		if($in{ffp_id} ne "") { $sql .= " and a.Corp_ffp='$in{ffp_id}' "; }
		if($in{air_type} ne "ALL") { $sql .= " and a.Air_type='$in{air_type}' "; }
		if($in{air_code} ne "%") { $sql .= " and l.Airline_ID='$in{air_code}' "; }
		$sql.=qq`\ngroup by case when '%'='$in{air_code}' then 'ALL' else l.Airline_ID end,d.First_name,d.Card_ID$id_group$cid_group$level_group
			having count(*)>=$in{air_times}
			order by 4 desc
			at isolation 0`;
		#if($in{User_ID} eq "admin"){
		#	print "<pre>$sql</per>";
		#	exit;
		#}
		$air_code{ALL}="所有航空公司";
		if ($in{is_down} eq "Y") {##下载报表   liangby@2011-4-28
			my $path="d:/www/Corp_extra/$Corp_ID/";
			if (! -e $path) {#目录不存在
				 mkdir($path,0002);
			}elsif(!-d $path){#存在文件但不是目录
				 mkdir($path,0002);
			}
			# 新建一个Excel文件
			my $ttime=$time;
			$ttime=~ s/\:*//g;
			my $ttoday=$today;
			$ttoday=~ s/\.*//g;
			my $context = new MD5;
			$context->reset();
			$context->add($Corp_ID."ffp_info".$ttoday.$ttime."richongqianlimugengshangy");
			my $md5_filename = $context->hexdigest;
			$BUF= $path.$md5_filename.".xls";
			$del_link="d:/www/Corp_extra/$Corp_ID/";
			$workbook;
			$workbook= Spreadsheet::WriteExcel::Big->new($BUF);
			# 新键一个工作簿
			$sheet_num=1;
			$worksheet = $workbook->addworksheet("协议旅客资料$sheet_num");

			##数据格式
			$format1 = $workbook->addformat();
			$format2 = $workbook->addformat();
			## 9号字体
			$format1->set_size(9);
			$format1->set_color('black');
			$format1->set_align('right');

			$format2->set_size(9);
			$format2->set_color('black');
			$format2->set_align('center');

			my $format="";
			## ----------------------------------------------------------------------------

			$iRow=0;
			$max_rows=60000;
			$worksheet->write_string($iRow,0,"航空公司",$format2);
			$worksheet->write_string($iRow,1,"旅客姓名",$format2);
			$worksheet->write_string($iRow,2,"证件号",$format2);
			$worksheet->write_string($iRow,3,"搭乘次数",$format2);
			if ($in{showis_A} eq "Y") {$worksheet->write_string($iRow,4,"会员",$format2);}
			if ($in{showis_B} eq "Y") {$worksheet->write_string($iRow,5,"客户",$format2);}
			if ($in{showis_C} eq "Y") {$worksheet->write_string($iRow,6,"客户级别",$format2);}
			$iRow++;

		}

		my $records = $in{perpage} eq '' ? 40 : $in{perpage};
		$Start = $in{Start};
		if($in{Start} eq "" || $in{Start} eq " ") { $Start=1; }
		my $t_records = $records*$Start;
		$Find_res = 0;
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$Find_res++;
					if($Find_res<=$Start*$records && $Find_res>($Start-1)*$records ){
						print "<tr bgcolor=f0fff0><td>$Find_res</td><td>$row[0].$air_code{$row[0]}</td><td>$row[1]</td><td>$row[2]</td><td>$row[3]</td>";
						if ($in{showis_A} eq "Y") {print "<td>$row[4]</td>";}
						if ($in{showis_B} eq "Y") {print "<td>$row[5]</td>";}
						if ($in{showis_C} eq "Y") {print "<td>$row[6]</td>";}
						print "</tr>";
					}
					if ($in{is_down} eq "Y") {
						if(($Find_res%$max_rows)==0){
							$sheet_num++;
							$worksheet = $workbook->addworksheet("协议旅客资料$sheet_num");
							$iRow=1;
							$worksheet->write_string($iRow,0,"航空公司",$format2);
							$worksheet->write_string($iRow,1,"旅客姓名",$format2);
							$worksheet->write_string($iRow,2,"证件号",$format2);
							$worksheet->write_string($iRow,3,"搭乘次数",$format2);
							if ($in{showis_A} eq "Y") {$worksheet->write_string($iRow,4,"会员",$format2);}
							if ($in{showis_B} eq "Y") {$worksheet->write_string($iRow,5,"客户",$format2);}
							if ($in{showis_C} eq "Y") {$worksheet->write_string($iRow,6,"客户级别",$format2);}
							$iRow++
						}
						$worksheet->write_string($iRow,0,"$row[0].$air_code{$row[0]}",$format1);
						$worksheet->write_string($iRow,1,"$row[1]",$format1);
						$worksheet->write_string($iRow,2,"$row[2]",$format1);
						$worksheet->write_number($iRow,3,"$row[3]",$format);
						if ($in{showis_A} eq "Y") {$worksheet->write_string($iRow,4,"$row[4]",$format1);}
						if ($in{showis_B} eq "Y") {$worksheet->write_string($iRow,5,"$row[5]",$format1);}
						if ($in{showis_C} eq "Y") {$worksheet->write_string($iRow,6,"$row[6]",$format1);}
						$iRow++;
					}
				}
			}
		}
		if ($Find_res == 0) {
			print qq`<tr><td colspan=5><font color=red>对不起，没有找到相关记录！</font><td></table></body></html>`;
			exit;
		}
		$Total_num=$Find_res;
		$in{is_down}='N';
		my $pageButtons = &showPages($Total_num, $records, $Start, 10, '', 1);
		my $colspan=5;
		if ($in{showis_A} eq "Y") {$colspan++;}
		if ($in{showis_B} eq "Y") {$colspan++;}
		if ($in{showis_C} eq "Y") {$colspan++;}
		print qq`
		<tr bgcolor=f0f0f0>
			<td height=20 colspan='$colspan'>
				<div style="clear: both; padding: 5px 0;">
					$pageButtons
				</div>
			</td>
		</tr></table>`;
		if ($BUF =~ /$Corp_ID/) {
			$workbook->close;
			## 写Excel结束-------------------------------------------------------
			my $fileName = $BUF;
			$fileName =~ s/^.*(\\|\/)//; #用正则表达式去除无用的路径名，得到文件名
			$D_SERVER=$G_SERVER;
			$downfile='/Corp_extra/'.$Corp_ID.'/'.$fileName;
			print qq!<table><tr><td>下载地址：<a href=$downfile  ><img src='/admin/images/download2.gif' border=0><font class=medium><b>下载</b></font></a></td></tr></table>!;
		}
		print "<br/>查询范围:1、只含正常订单； 3、不含被退、被废； 2、证件号码长度大于等于4";
	}
}

print qq`
<script language="javascript">
	function loadTickagent_ID(){
		if (typeof(window.version1) == 'undefined') {
			var s = document.createElement('script');
			s.setAttribute('type','text/javascript');
			s.setAttribute('src','/admin/js/suggest/suggest_new.js');
			var head = document.getElementsByTagName('head');
			head[0].appendChild(s);
		}
	}
	function addLoadEventTickagent_ID(func) {
		var oldonload = window.onload;
		if (typeof window.onload != 'function') {
			window.onload = func;
		}else{
			window.onload = function() {
				oldonload();
				func();
			}
		}
	}
	addLoadEventTickagent_ID(loadTickagent_ID);
</script>
</body></html>`;

sub write_log{
	local($s_msg)=@_;
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
	$log_path .="/ajax_logs/";
	if (! -e $log_path) {#目录不存在
		 mkdir($log_path,0002);
	}elsif(!-d $log_path){#存在文件但不是目录
		 mkdir($log_path,0002);
	}
	$filename=">> $log_path"."ajax_logs_$file_date.log";
	open MAIL,"$filename" || die "错误：不能打开文件";
	print MAIL "---------------------- $today2" || die "error"; 
	print MAIL " $s_msg \n";
	close(MAIL);
}