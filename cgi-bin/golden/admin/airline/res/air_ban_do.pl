#!c:/Perl/bin/Perl.exe
require "ctnlib/golden/common.pl";
require "ctnlib/golden/cgi-lib.pl";
require "ctnlib/golden/html.pl";
require "ctnlib/golden/air_res.pl";
require "ctnlib/golden/manage.pl";
require "ctnlib/golden/air_pay_op.pl";
require "ctnlib/golden/air_pay_op1.pl";
require "ctnlib/golden/my_sybperl.pl";

use MD5;
use Sybase::CTlib;
## =====================================================================
## start program
## =====================================================================
&ReadParse();
## =====================================================================
&Header("��ƺ���-$in{Reservation_ID}","","Y");
## =====================================================================
print qq!<link rel="stylesheet" type="text/css" href="/admin/style.css" />
<link rel="stylesheet" type="text/css" href="/admin/style/style.css" />
<link rel='stylesheet' href='http://$G_SERVER/style/member/style.css' type='text/css'>
<link href="/admin/js/popdialog/style.css" rel="stylesheet" type="text/css" />
!;

my $p_mod_extra=" class='readonly'";	## 022000 Ʊ̨�˶��ڽ��л�ƺ���ʱ���Ƿ������޸��ⲿ�����	 dabin@2015-12-08
if ($in{Sign} ne "") {
	my $md5str = "User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID=$in{Reservation_ID}"."dabinbuzhidao";
	## ����MD5ǩ��
	my $context = new MD5;
	$context->reset();
	$context->add($md5str);
	my $md5_str = $context->hexdigest;
	if ($md5_str ne $in{Sign}) {
		print MessageBox("������ʾ","<font color=red>����ǩ����֤ʧ�ܣ�</font>");
		exit;
	}
	$db=connect_database();
	## ������Ա�Ƿ�����Ȩ��ƺ���Ȩ��	dabin@2015-12-08
	$sql = "select Function_ID from ctninfo..User_ACL where User_ID='$in{User_ID}' and Function_ID = 'HSKJ' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$p_mod_extra=" class='input_num'";
			}
		}
	}
}
else{
	$Corp_ID = ctn_auth("HSKJ");
	if(length($Corp_ID) == 1) { exit; }
	$p_mod_extra=" class='input_num'";
	$sql = qq?select Function_ID from ctninfo..User_ACL where User_ID='$in{User_ID}' and Function_ID='COMM' \n?;
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$ban_show_status=$row[0];
			}
		}
	}
	if($ban_show_status ne '') { #�л�ƺ���Ȩ�޿����޸�ͬ�з�Ӷ����ͻ�ƺ��� hecf 2014/12/17
		$ban_show=qq`<tr><td>
			<div class='tabNav'>
				<ul>
					<li><a href="air_comm_do.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID=$in{Reservation_ID}" title='��Ӷ����'>��Ӷ����</a></li>
					<li class='current' ><a href="air_ban_do.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID=$in{Reservation_ID}">��ƺ���</a></li>
				</ul>
			</div>
		</td></tr>`; 
	}
}

## =======================================
#print "<body topmargin=2 leftmargin=2 rightmargin=2>";
print qq`
<style>
	.Cmttemplate{ background:#2292DD; border:1px solid #bceaff; padding:2px 3px; color:#ffffff; text-decoration:none;}
	.Cmttemplate:hover{ background:#0066cc; border:1px solid #62b9e7; padding:2px 3px;color:#ffffff;text-decoration:none;}
</style>
<script type="text/javascript" src="/admin/js/popdialog/popdialog.js"></script>
<script type="text/javascript" src="/admin/js/popwin.js?ver=20110601"></script>
<script type="text/javascript" src="/admin/js/global.js?ver=20110601"></script>
<script type="text/javascript" src="/admin/js/ajax/jquery-1.3.2.min.js" charset="gb2312"></script>
<script type="text/javascript">
var removeAll = function(obj)
{
	obj.options.length=0;
}
//�������Ԫ���Ƿ����
function array_exists(arr, item)
{
	for (var n = 0; n < arr.length; n++)
	if (item == arr[n]) return true;
	return false;
}
self.resizeTo(800,480);
function cmt_add(cmt){
	var Comment=document.operate.Comment;
	if (Comment.value=="" || Comment.value==" ") {
		Comment.value=cmt;
	}else{
		Comment.value=Comment.value+'\\n'+cmt;
	}
}

function Get_ticket_id(obj,tkt_num){
	if('$Corp_center' != '022000'){
		return;
	}
	var obj_name=obj.name;
	var aircode_id=obj_name.replace(/tk_num/i,'aircode');
	if(obj.value=='J' || obj.value=='j'){
		var air_code='';
		var resid=document.operate.Reservation_ID.value;
		if(obj.tktid==null || obj.tktid==''){
			\$.ajax({
				url: "/cgishell/golden/admin/airline/res/change.pl?f=" + Math.random(),
				dataType: 'text', 
				type: "post",
				data: {User_ID:"$in{User_ID}",Serial_no:"$in{Serial_no}",Action:"Get_tktid",Res_ID:resid,Tkt_num:tkt_num},
				async: true,
				success: function(data) {
					obj.tktid=data;
					var reg=/(\\w{3})(\\d{10})/;
					if(reg.test(obj.tktid)){
						air_code=RegExp.\$1;
						obj.value=RegExp.\$2;
						document.getElementById(aircode_id).value=air_code;
					}
				}
			});
		}
		else{
			var reg=/(\\w{3})(\\d{10})/;
			if(reg.test(obj.tktid)){
				air_code=RegExp.\$1;
				obj.value=RegExp.\$2;
				document.getElementById(aircode_id).value=air_code;
			}
		}
	}
	else if(obj.tktid !='' && obj.tktid.substr(3,10)!=obj.value){
		document.getElementById(aircode_id).value=document.getElementById(aircode_id).getAttribute('old_value')?document.getElementById(aircode_id).getAttribute('old_value'):document.getElementById(aircode_id).old_value;
	}
}
</script>
<div id="append_parent"></div>
`;
&get_op_type();
&show_air_js();
## ��ѯС�����ȷλ��	liangby@2009-1-8
$Dec_round = "%.1f";
$Dec_round_2=2;
$sql = "select Socket_ID,Air_parm from ctninfo..Corp_extra where Corp_ID='$Corp_center' "; 
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			if ($row[0] ne "") {
				$Dec_round = "%.$row[0]"."f";
	            $Dec_round_2=$row[0];
			}
			$Air_parm=$row[1];
		}
	}
}
## ��ѯԤ����Ϣ
my $res_find =$recv_total=0;
my $tbook="_$Top_corp";
$sql = qq!select convert(char(10),a.Book_time,102)+' '+convert(char(5),a.Book_time,108),
		a.Book_status,a.Contact,a.Usertel,a.Userbp,a.Useremail,rtrim(a.User_address),
		a.Pay_method,rtrim(a.Comment),a.Abook_method,b.Corp_csname,a.Corp_ID,c.Corp_csname,
		a.AAboook_method,a.Agent_ID,a.yewu,a.Booking_ref,a.Air_type,a.User_ID,
		convert(char(10),getdate(),102),convert(char(5),dateadd(minute,10,getdate()),108),
		convert(char(5),dateadd(minute,40,getdate()),108),
		convert(char(10),a.S_date,102)+' '+convert(char(5),a.S_date,108),a.Delivery_method,
		a.Sender_ID+'['+d.First_name+d.Last_name+']',convert(char(10),a.S_date,102),a.Send_stime,a.Send_atime,
		a.Recv_total,a.Insure_recv,right(convert(char(10),getdate(),102),5)+' '+convert(char(5),getdate(),108),
		a.If_out,'',a.Alert_status,a.Is_share,rtrim(a.Office_ID),a.ET_price,a.In_total,a.Ticket_time,a.Pay_kemu,        
		a.Pay_bank,a.Left_total,a.Tag_str,a.Adult_num,a.Child_num,a.Baby_num,a.Insure_type,rtrim(a.Dev_by),Return_total, 
		rtrim(a.Old_resid)
	from ctninfo..Airbook_$Top_corp a,
		ctninfo..Corp_info b,
		ctninfo..Corp_info c,
		ctninfo..User_info d
	where a.Corp_ID=c.Corp_ID   and c.Corp_num='$Corp_center'
		and a.Agent_ID=b.Corp_ID and b.Corp_num='$Corp_center'
		and a.Sender_ID*=d.User_ID
		and d.User_type = 'Y' and d.Corp_num='$Corp_center'
		and a.Reservation_ID = '$in{Reservation_ID}' !;
if ($Corp_type eq "T" ) {	## Ԥ������
	$sql .= "and a.Sales_ID='$Corp_ID' ";
}
else{
	$sql .= "and (a.Corp_ID = '$Corp_ID' or a.Agent_ID = '$Corp_ID') ";
}
$db->ct_execute($sql);	
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT) {
		while(@row = $db->ct_fetch) {
			$Book_time=$row[0];		$Book_status=$row[1];	$guest_name=$row[2];
			$guest_tel=$row[3];		$guest_bp=$row[4];		$guest_email=$row[5];
			$guest_address=$row[6];	$comm_method = $row[13];			
			$Comment=$row[8];		
			$Comment =~ s/\n//g;		$Comment =~ s/\r//g;		$Comment =~ s/\\//g;	$Comment =~ s/\'//g;	$Comment =~ s/\"/��/g;
			$agent_name=$row[10];	$corp_id=$row[11];		$corp_name=$row[12];
			$agent_id=$row[14];		$yewu=$row[15];			$row[16] =~ s/\s*//g;
			$booking_ref=$row[16];	$air_type=$row[17];		
			$s_date = $row[19];		$s_time=$row[20];		$a_time=$row[21];
			$r_time=$row[22];		$d_method=$row[23];		$d_user=$row[24];
			$d_date=$row[25];		$d_dtime=$row[26];		$d_atime=$row[27];
			$card_no=$row[18];		if ($booking_ref eq "") {	$booking_ref="-----";	}
			$res_find ++;			$d_method = &cv_delivery($d_method,'');
			$recv_total=$row[28];	$now=$row[30];
            ##���״̬           liangby@2008-3-6
			$If_out=$row[31];		$is_refund=$row[33];
			$yd_pay=$row[34];		$yd_pay=~ s/\s*//g;		$office_id=$row[35];
			$in{old_et_price}=$ET_price=$row[36];		$old_tkt_time=$row[38];	$Pay_kemu=$row[39];
			$Pay_kemu=~ s/\s*//g;
			$in{old_bank_id}=$bank_id=$row[40];		$Tag_str=$row[42];		$Adult_num=$row[43];
			$Child_num=$row[44];	$Baby_num=$row[45];		$Insure_type=$row[46];
			$bank_id=~ s/\s*//g;	$old_b2b_user=$row[47];
			$old_in_total=$row[37];
			if ($ET_price eq "" || $ET_price eq "0") {
				$ET_price=$row[37];
			}
			$bk_status=&cv_airstatus($Book_status,'S',$row[41],"",$is_refund);
			$profit_up=$row[48];	$Old_resid=$row[49];
		}
	}
}
$Lock_off="";
if (&Binary_switch($Function_ACL{HSKJ},1,'A')==0 && $Tag_str=~/��/) {
	$Lock_off="Y";
}

my $p_reads = "class='input_num'";
if ($Lock_off eq "Y") {
	$Lock_sreadonly=' readonly="readonly" class="input_border"';
	$p_read='';$p_mod_extra="";
	$lock_disd=" disabled ";
	$lock_tips="<b><font color=red>��������������</font></b>";
}
#if ($air_type eq "Y" && ($G_ZONE_ID eq "3" || $Corp_center eq "ESL003" || $Corp_center eq "CAN521")) {
	#print qq`
	#<form action='air_ban_do_y.pl' name=air_ban method=post>`;
		#foreach $arr (sort keys(%in)) {
			#print qq`<input type=hidden name="$arr" value="$in{$arr}">`;
		#}
	#print qq`
	#</form>
	#<script type="text/javascript">document.air_ban.submit();</script>`;
	#exit;
#}

my $bank_list="<option value=''>ѡ������</option>";
if ($Pay_version eq "1") {	## ��ȡ��Ŀ��B2B/�⹺�����˻���Ϣ	dabin@2010-12-15
	my @kemu_array=&get_kemu($Corp_center,"","array","3","Y","","assist","","","Y");	
	## ������Ŀ
	%assist_hash=&get_kemu($Corp_center,"","hash","","","","assist","","","Y");	
	my @tmp_kemu_array = ();

	if ($bank_id eq "N") {
		##δ���㣬һ�����⹺ʹ��    liangby@2016-7-25
		push(@tmp_kemu_array, "['SKYECH', 'N', 'δ����', '3','']");
	}
	
	for (my $i = 0; $i < scalar(@kemu_array); $i++) {
		
		push(@tmp_kemu_array, "['$kemu_array[$i]{Corp_ID}', '$kemu_array[$i]{Type_ID}', '$kemu_array[$i]{Type_name}','$kemu_array[$i]{Pic}','$kemu_array[$i]{Pid}']");
		$assist_hash{$kemu_array[$i]{Type_ID}}=$kemu_array[$i]{Type_name};
	}
	$kemulist = join(',', @tmp_kemu_array);
	$kemuscript = qq`
		if (type == 'Y') {	//BSP
			changeKemu(kemulist, 'a', '$bank_id');
		}
		else if (type == 'B') {	//B2B
			changeKemu(kemulist, '0', '$bank_id');
		}
		else if (type == 'O') {	//BOP
			changeKemu(kemulist, '4', '$bank_id');
		}
		else if (type == 'C') {	//B2C
			changeKemu(kemulist, '2', '$bank_id');
		}
		else if (type == 'W') {	//�⹺
			changeKemu(kemulist, '3', '$bank_id');
		}else if (type == 'G') {	//GP
			changeKemu(kemulist, '5', '$bank_id');
		}else if (type == 'U') {	//UATP
			changeKemu(kemulist, '6', '$bank_id');
		}else if (type == 'L') {	//B2G
			changeKemu(kemulist, '8', '$bank_id');
		}else if (type == 'T') {	//B2T
			changeKemu(kemulist, '9', '$bank_id');
		}
		`;
	print qq!<script>
		function get_paykemu(){
			var val=document.operate.pay_by.value;
			for (var i = 0; i < kemulist.length; i++) {
				if (kemulist[i][1] == val) {
					document.operate.Pay_kemu.value=kemulist[i][4];
					break;
				}
			}
		}
		</script>!;
	$getscript=qq! onchange="get_paykemu();"!;
	## �ͻ���Ϣ
	%corp_info =&corps_dept("$corp_id");
}
else{
	my $sql="select rtrim(pay_id),pay_name from ctninfo..d_pay_by where corp_id='$Corp_center' order by pay_id";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row=$db->ct_fetch)	{
				$assist_hash{$row[0]}=$row[1];
				if ($bank_id eq $row[0]) {
					$bank_list .= "<option value='$row[0]' selected >$row[1]</option>";
				}else{
					$bank_list .= "<option value='$row[0]' >$row[1]</option>";
				}				
			}
		}
	}
}
## Ʊ֤��Դ
my $office_list="<option value=''>---- Ʊ֤��Դ ---</option>";
my @office_array = &get_office($Corp_office,"","array","A","","Y");
## ��Ӧ��Ϊ��ͣ״̬ҲҪ��ʾ miaosc@2013-5-22
my $sql_a="select Office_ID,Office_name,Out_tkt,Office_type from ctninfo..Corp_office 
			where Corp_ID='$Corp_center' and Office_ID='$office_id' and Status='N' and Office_type='A'";
$db->ct_execute($sql_a);			
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT) {
		while(@row_a = $db->ct_fetch) {
			if ($row_a[0] ne "") {
				push(@office_array, {'id' => $row_a[0], 'name' => $row_a[1], 'type' => $row_a[2]});
			}
			
		}
	}
}
my $officelist = '';
my @tmp_office_array = ();
for (my $i = 0; $i < scalar(@office_array); $i++) {
	if ($office_array[$i]{id} ne '') {
		push(@tmp_office_array, "['$office_array[$i]{id}', '$office_array[$i]{name}', '$office_array[$i]{type}','']");
	}
	my $sel;	if ($office_id eq $office_array[$i]{id}) {	$sel=" selected";	}
	if ($in{Is_ET} eq "W") {
		my $f_color="style='color:red;'";	
		if ($office_array[$i]{type} eq "P") {	$f_color="style='color:magenta;'";		}
		if ($office_array[$i]{type} ne "Z") {
			$office_list .= "<option value='$office_array[$i]{id}'$sel $f_color>$office_array[$i]{id} $office_array[$i]{name}</option>\n";
		}		
	}
	else{
		if ($office_array[$i]{type} eq "Z") {
			$office_list .= "<option value='$office_array[$i]{id}'$sel>$office_array[$i]{id} $office_array[$i]{name}</option>\n";
		}	
	}
}
$sql="select b.Airline_ID
from ctninfo..Airbook_lines_$Top_corp b,
	ctninfo..Airbook_detail_$Top_corp c
where b.Reservation_ID='$in{Reservation_ID}' 
	and b.Reservation_ID=c.Reservation_ID 
	and b.Res_serial=c.Res_serial
	and b.Res_serial=0
	and c.Last_name='0' ";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			$airline=$row[0];
		}
	}
}
##B2B��office��    liangby@2013-3-18
$sql=" select rtrim(Pay_user_id),rtrim(Office_ID),Airline_code from ctninfo..AirNetPay where Corp_ID='$Corp_center' and Airline_code='$airline' and Office_ID+''<>'' order by Airline_code,Pay_user_id ";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if ($restype==CS_ROW_RESULT)	{
		while(@row=$db->ct_fetch)	{
			push(@tmp_office_array, "['$row[1]-$row[0]', '', 'B','$row[0]']");
		}
	}
}
$officelist = join(',', @tmp_office_array);
## Ʊ֤����
my @tkt_type=&get_dict($Corp_center,3,"");
for (my $i=0;$i<scalar(@tkt_type);$i++) {
	$tkt_type_name{$tkt_type[$i]{Type_ID}}=$tkt_type[$i]{Type_name};
}
if ($Corp_center eq "ESL003" || $Corp_center eq "022000" || $Corp_center eq "CAN521") {##�ⲿ������ݲ��������ͻ�����   liangby2015-2-13
	$use_extra_inprice="Y";
}
my $disp_old;  my $can_write="N";  my $old_str;
if ($is_refund eq "1" || $is_refund eq "2" || $is_refund eq "3") { ## �˷�,���� ԭ���ŵ�����   jf@2018-01-03
	my $book_status;
	if ($Old_resid ne ""){
		my $sql="select Book_status from ctninfo..Airbook_$Top_corp where Reservation_ID='$Old_resid' \n";	
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$book_status=$row[0];
				}
			}
		}
	}
	if ($Old_resid eq "" || ($book_status eq "C" &&  &Binary_switch($Function_ACL{HSKJ},1,'A')==1)){
		$disp_old= qq`<td>ԭ �� �ţ�<input name="old_resid" value="$Old_resid"></td>`;
		$can_write="Y"; 
	}
}
if ($in{Op} eq "W") {	## д������
	##��֧������Ϊ��ȴ����ƾ֤��   liangby@2013-12-28
	$in{Comment}=~ s/\\//g;
	$in{Comment} =~ s/'/��/g;	
	$in{Comment} =~ s/"/��/g;
	$in{Comment} =~ s/\n//g;		
	$in{Comment} =~ s/\r//g;		
	#if ($Tag_str=~/\!/ && $Pay_kemu ne "") {
	#	print MessageBox("������ʾ","<font color=red>���������ɻ��ƾ֤�����������޸Ĵ���ѡ�Ʊ֤���͵���Ϣ��|$Pay_kemu|");
	#	exit;
	#}
	
	if ($Tag_str=~/5/) {
		print MessageBox("������ʾ","<font color=red>�����ѳ��˵������������޸Ĵ���ѡ�Ʊ֤���͵���Ϣ��");
		exit;
	}
	if ($Tag_str=~/\!/) {## liangby@2016-11-25
		print MessageBox("������ʾ","<font color=red>����������ƾ֤�����������޸Ĵ���ѡ�Ʊ֤���͵���Ϣ��");
		exit;
	}
	
	## ---------------------------------------------
	## ��ѯԤ����Ϣ
	## ---------------------------------------------
	$sql="select b.Book_status,convert(char(10),c.Air_date,102),b.User_ID,b.If_out,b.Sales_ID,
		rtrim(b.Comment),b.Air_settle,b.Tag_str
		from ctninfo..Airbook$tbook b,
			ctninfo..Airbook_lines$tbook c
		where b.Reservation_ID = c.Reservation_ID
			and b.Reservation_ID='$in{Reservation_ID}'
			and c.Res_serial=0 ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$old_status=$row[0];	
				$air_date=$row[1];		$user_id=$row[2];
				$If_out=$row[3];		$sales_id=$row[4];		$old_comment=$row[5];
				$settle_air=$row[6];	$old_tag_str=$row[7];
			}
		}
	}
	$sql=" select User_type,Card_no from ctninfo..User_info where User_ID='$user_id' and Corp_num='$Corp_center' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$user_type=$row[0];	 $card_no=$row[1];
			}
		}
	}
	## ��ѯ����ԭ���ߺ�ԭ����
	my $j=0;
	$sql="select In_price,In_discount,Air_code,Ticket_ID,Ticket_LID,rtrim(Insure_no),SCNY_price,Extra_inprice,In_tax,In_yq,In_fee
		from ctninfo..Airbook_detail$tbook where Reservation_ID='$in{Reservation_ID}' 
		order by Res_serial,convert(tinyint,Last_name) ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$old_in_price[$j]=$row[0];
				$old_in_dis[$j]=$row[1];
				$old_air_code[$j] = $row[2];
				$old_ticket_id[$j] = $row[3];
				$old_ticket_lid[$j] = $row[4];

				$print_no[$j] = $row[5];
				if ($row[6] eq "") {
					$row[6]=0;
				}
				$old_scnyprice[$j]=$row[6];
				$old_extra_inprice[$j]=$row[7];
				$old_intax[$j]=$row[8];
				$old_inyq[$j]=$row[9];
				$old_infee[$j]=$row[10];
				$j++;
			}
		}
	}
	if ($in{et_type} eq "W" && $in{office_id} eq "") {##�⹺Ʊ֤��Դ����Ϊ��   liangby@2011-6-21
		print MessageBox("������ʾ","�Բ�����ѡ��Ʊ֤��Դ��"); 
		exit;
	}
	if (($in{et_type} eq "Y" || $in{et_type} eq "W" || $in{et_type} eq "O" || $in{et_type} eq "G" ) && $in{office_id} eq "") {##BSP��BOP��GP office_id����Ϊ��  liangby@2014-11-14
		print MessageBox("������ʾ","�Բ�����ѡ��Office_ID��"); 
		exit;
	}
	if (($in{et_type} eq "B" || $in{et_type} eq "C" || $in{et_type} eq "O" || $in{et_type} eq "G" || $in{et_type} eq "U") && $in{pay_by} eq "") {
		print MessageBox("������ʾ","�Բ�����ѡ��֧�����У�"); 
		exit;
		
	}
	if (&Binary_switch($Function_ACL{HSKJ},1,'A')==0 && $old_tag_str=~/��/) {
		print "<font color=red>�Բ��𣬶���$in{Reservation_ID}�����ѱ���������ֹ���в���,����������Ȩ�޵Ĺ��Ųſ��Բ�����</font><br>";
		exit;
	}
	
	my $remark=""; my $is_change=0;
	$sql_upt = "begin transaction sql_insert 
		declare \@t_reward integer \n";
	## ����������¼
	$sql_upt .="insert into ctninfo..Res_op values('$in{Reservation_ID}','A','$in{User_ID}','A',getdate()) \n";
	## ������ϸ
	if ($in{et_price} eq "") {	$in{et_price}=0;	}
	if ($Pay_version == "1") {	
		$sql_payby1=",Pay_bank='$in{pay_by}'";	
	}	
	else{	
		$sql_payby2=",Insure_mode='$in{pay_by}'";	
	}
	if ($in{old_tkt_time} eq "" && $old_tkt_time ne "") {##�����˻��ȴ򿪻�ƺ���ҳ�棬Ȼ�����˷ϴ���󣬵����ƺ���ȷ����ť����Is_ET�������    liangby@2013-9-6
		print MessageBox("������ʾ","����״̬�Ѹı䣬����ʧ��"); 
		exit;
	}
	if ($old_comment ne $in{Comment}) {
		$remark .="��ע:$old_comment->$in{Comment}";
		$is_change=1;
	}
	for ($i=0;$i<$in{T_num};$i++) {
		my $ss = "id_".$i;			my $in_dis="in_dis_$i";		my $agt_dis="agt_dis_$i";	
		my $tk_num="tk_num_$i";		my $tk_in="tk_in_$i";       my $tk_out="tk_out_$i";
		my $cust_name="cust_name_$i";	my $depart = "depart_$i";	my $arrive = "arrive_$i";
		my $aircode = "aircode_$i";	my $print_no = $in{"print_no_$i"};	my $tk_lnum=$in{"tk_lnum_$i"};
		my $up_dis="Up_price_dis_$i";  my $up_price="Up_price_$i";   my $Extra_inprice="Extra_inprice_$i";
		my $old_indisrate="old_indisrate_$i";
		my $in_tax="tk_intax_$i"; my $in_yq="tk_intyq_$i"; my $in_fee="in_fee_$i";

        if ($in{$up_dis} eq "") {
           $in{$up_dis}=0;
        }
		if ($in{$up_price} eq "") {
           $in{$up_price}=0;
        }
		
		
		my $scny_price="tk_scny_$i";
		if ($in{$scny_price} eq "") {
			$in{$scny_price}="0";
		}
		if ($in{$in_tax} eq "") {
			$in{$in_tax}=0;
		}
		if ($in{$in_yq} eq "") {
			$in{$in_yq}=0;
		}
		$tk_num = $in{$tk_num};
		my $ticket_num = $in{$aircode} . $tk_num;
		if ($tk_num eq "") {	$tk_num = 0;	}
		if ($tk_lnum eq '') {
			$tk_lnum = 0;
		}
		my ($s_id,$p_id) = split(",",$in{$ss});
		
		if ($in{$scny_price} !=0) {
			$in{$in_dis}=sprintf("%.2f",((($in{$scny_price}-$in{$tk_in})/$in{$scny_price})*100)+0.000001);
			
		}else{
			$in{$in_dis}=0;
		}
	
		my $new_agentfee=sprintf("%.2f",$in{$scny_price}-$in{$tk_in});
		$in{$tk_in}=sprintf("$Dec_round",$in{$tk_in}); 
		$old_in_price[$i]=sprintf("$Dec_round",$old_in_price[$i]);
		if ($p_id == 0 && $Lock_off ne "Y") {	##ֻ�����һ���˿͵�����  likunhua@2009-06-01
			if ($old_in_price[$i] ne $in{$tk_in} || $old_in_dis[$i] ne $in{$in_dis} || $old_scnyprice[$i] !=$in{$scny_price} 
			 || ($old_extra_inprice[$i] != $in{$Extra_inprice} && $use_extra_inprice eq "Y") || $old_intax[$i] != $in{$in_tax} || $old_inyq[$i] !=$in{$in_yq} || $old_infee[$i] != $in{$in_fee}) {	##ԭ���ߺ�ԭ���ۺ�ҳ������ݲ�һ��
				$remark .="�˿�$in{$cust_name}";
				if ($old_in_price[$i] ne $in{$tk_in} || $old_in_dis[$i] ne $in{$in_dis}) {
					$remark .=",�׼�$old_in_price[$i]"."->"."$in{$tk_in},";
					if ($in{Usedisrate} eq "Y") {##ԭ���Ƕ�������    liangby@2016-7-21
						if ($in{$old_indisrate} !=$new_agentfee) {
							$remark .="��������$in{$old_indisrate}"."->"."$new_agentfee";
						}
						
					}else{
						$remark .="����$old_in_dis[$i]"."->"."$in{$in_dis}";
					}
				}
				if ($old_scnyprice[$i] !=$in{$scny_price}) {
					$remark .=",SCNY$old_scnyprice[$i]"."->"."$in{$scny_price}";
				}
				if ($old_extra_inprice[$i] != $in{$Extra_inprice} && $use_extra_inprice eq "Y") {
					$remark .=",�ⲿ�����$old_extra_inprice[$i]"."->"."$in{$Extra_inprice}";
				}
				if ($air_type eq "Y") {
					if ($old_intax[$i] != $in{$in_tax} ){
						$remark .=",����˰$old_intax[$i]"."->"."$in{$in_tax}";
					}
				}else{
					if ($old_intax[$i] != $in{$in_tax} ){
						$remark .=",�������˰$old_intax[$i]"."->"."$in{$in_tax}";
					}
					if ($old_inyq[$i] !=$in{$in_yq}) {
						$remark .=",����ȼ�ͷ�$old_inyq[$i]"."->"."$in{$in_yq}";
					}
				}
				if ($old_infee[$i] != $in{$in_fee}) {
					$remark .=",��������$old_infee[$i]"."->"."$in{$in_fee}";
				}
				$is_change=1;
			}
		}
		
		if ($air_type eq "N" && $Air_parm =~/Z/ && $in{et_type} ne "W") {##����ƱĬ����Ҫsncy�۸�У���,�⹺�Ĳ�У��?   liangby@2014-5-15
			if ($in{$scny_price}>$in{$tk_out}) {
			
				print MessageBox("������ʾ","���ۼ�($in{$tk_out})����С��SCNY($in{$scny_price}),���費���ƣ����ڲ������ò�����SCNYУ��"); 
				exit;
				
			}
		}
		if ($in{$Extra_inprice} eq "") {
			$in{$Extra_inprice}=0;
		}
		if ($in{$in_fee} eq "") {
			$in{$in_fee}=0;
		}
		$sql_upt .= "update ctninfo..Airbook_detail_$Top_corp
						set Ticket_ID=$tk_num "; 
		if ($Lock_off ne "Y") {
			$sql_upt .=" ,In_discount=$in{$in_dis},In_price=$in{$tk_in},Ticket_LID=$tk_lnum,SCNY_price=$in{$scny_price} ";
			if ($old_intax[$i] != $in{$in_tax} ){
				$sql_upt .=",In_tax=$in{$in_tax}";
			}
			if ($old_inyq[$i] !=$in{$in_yq}) {
				$sql_upt .=",In_yq=$in{$in_yq}";
			}
			if ($old_infee[$i] !=$in{$in_fee}) {
				$sql_upt .=",In_fee=$in{$in_fee}";
			}
			if ($use_extra_inprice eq "Y") {
				$sql_upt .=" ,Extra_inprice=$in{$Extra_inprice}";
			}
			if ($in{Usedisrate} eq "Y" ) {##��������   
				if ($in{$old_indisrate} !=$new_agentfee) {
					$sql_upt .=" ,In_disrate=$new_agentfee";
				}
				
			}else{
				$sql_upt .=" ,In_disrate=0";
			}
			if ($air_type eq "Y" && $is_refund eq "0" ) {#����Ʊ ���ҷ��˷�

				$sql_upt .= ",Return_spfee=$in{$up_dis},Return_price=$in{$up_price} ";
			}
			
			if ($old_tkt_time ne "") {
				$sql_upt .=",Is_ET='$in{et_type}'$sql_payby2 ";
			}
		}
		
		if ($old_air_code[$i] ne $in{$aircode}) {	## �����޸ĳ�Ʊ���� jeftom@2011-12-7
			$sql_upt .= ", Air_code='$in{$aircode}'";
			$remark .=",��Ʊ����:$old_air_code[$i]" . '->' . "$in{$aircode}";
			$is_change=1;
			if($i==0){ ##���½��㺽˾ lyq@2016-04-11
				my $settle_sql="select top 1 Airline_code from ctninfo..Airlines where Airline_ID='$in{$aircode}' at isolation 0";
				$db->ct_execute($settle_sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							$settle_air=$row[0];
						}
					}
				}
			}
		}
		if ($old_ticket_id[$i] ne $tk_num || $old_ticket_lid[$i] ne $tk_lnum) {	## ����������Ʊ�� jeftom@2011-12-8
			$remark .=",Ʊ��:$old_ticket_id[$i]-$old_ticket_lid[$i]" . '->' . "$tk_num-$tk_lnum";
			$is_change=1;
		}
		$print_no[$i]=~ s/\s*//g;
		$print_no=~ s/\s*//g;
		if ($print_no[$i] ne $print_no || $in{et_type} ne 'Y') {
			if ($in{et_type} eq 'Y' || (($is_refund eq "1" || $is_refund eq "2") && $in{et_type} eq "")) {	## BSPƱ�������޸Ĵ�Ʊ���� jeftom@2011-12-8
				##�˷�Ʊδ������ɵģ�Ҫ�޸Ĵ�Ʊ������ʹ��������Ʊ   liangby@2012-9-18
				$sql_upt .= ", Insure_no='$print_no'";
				$remark .=",��Ʊ����:$print_no[$i]" . '->' . "$print_no";
				$is_change=1;
			}
			elsif($print_no[$i] ne "") {
				$sql_upt .= ", Insure_no=''";
				$remark .=",��BSP��Ʊ�����ÿ�:$print_no[$i]" . '->';
				$is_change=1;
			}
			
		}
		$sql_upt .="\nwhere Res_serial=$s_id and Last_name='$p_id' and Reservation_ID='$in{Reservation_ID}' \n";
		if ($in{Contrast_target} eq 'Y') {
			## �����´����ʱ�޸ı���Ա����� jeftom @2010-12-17
			$sql_upt .= "UPDATE ctninfo..Contrast_Data SET Ticket_status='Y' WHERE ID=$in{Contrast_ID} AND Reservation_ID='$in{Reservation_ID}' AND Ticket_status='N'\n";
		}
		## ����״̬
		if ($in{profit_up} eq "") {
		   $in{profit_up}=0;
		}
	}
	$in{old_resid}=~ s/\s*//g;
	if ($can_write eq "Y" && ($Old_resid eq "" || $in{old_resid} ne $Old_resid)) { ## �������Ķ������Ƿ���Ч 
		my $timer=0; my $where;
		my $sql="select rtrim(a.Reservation_ID) from ctninfo..Airbook$tbook a where a.Reservation_ID='$in{old_resid}' ";

		if ($is_refund eq "1" || $is_refund eq "2") {##�˷�
			$where .=" and a.Book_status in ('P','S','H') and a.Alert_status in ('0','3','4','5')  ";
		}elsif($is_refund eq "3"){##����
			$where .=" and a.Book_status in ('P','S','H') and a.Alert_status='0' ";
		}
		$sql .= $where;
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$timer="1";
				}
			}
		}
		if($timer<1){
			print MessageBox("������ʾ","�Բ�������д��Ч�Ķ����ţ�"); 
			exit;
		}
		$old_str=" ,Old_resid='$in{old_resid}' ";  ## TIPS:����������
		$remark .="ԭ����:$Old_resid->$in{old_resid},";
		$is_change=1;
	}
	$in{profit_up}=sprintf("%.2f",$in{profit_up});
	$sql_upt .= "update ctninfo..Airbook_$Top_corp 
		set Tkt_num=(Adult_num+Child_num+Baby_num)*(select sum(case when isnull(Ticket_LID,0)=0 or isnull(Ticket_LID,0)>1000000000 then 1 
				else Ticket_LID-convert(decimal(10,0),right(convert(varchar,Ticket_ID),len(convert(varchar,Ticket_LID))))+1 end)  
				from ctninfo..Airbook_detail_$Top_corp where Reservation_ID='$in{Reservation_ID}' and Res_serial=0 and Last_name='0'),
				In_total=(select sum(In_price+isnull(In_tax,0)+isnull(In_yq,0)) from ctninfo..Airbook_detail_$Top_corp where Reservation_ID='$in{Reservation_ID}'),\nIs_account='Y',
				Return_total=$in{profit_up},Comment='$in{Comment}',Air_settle='$settle_air' $old_str ";
	if ($old_tkt_time ne "" && $Lock_off ne "Y") {
		if ($in{old_et_type} ne $in{et_type}) {
			my $old_t_name=$tkt_type_name{$in{old_et_type}};
			my $new_t_name=$tkt_type_name{$in{et_type}};
			$remark .="Ʊ֤:$old_t_name->$new_t_name,";
			$is_change=1;
		}
		if($in{et_type} eq "G") { #֧��״̬
			my $old_gp_tag="";
			$in{pay_tag}=~s/\s*//g;
			if($old_tag_str=~/(��|��)/){
				my $old_gp_tag=$1;
			}
			if($old_gp_tag ne $in{pay_tag}){
				$old_tag_str=~s/(��|��)//g;
				$old_tag_str.=$in{pay_tag};
				$sql_upt .= ",Tag_str='$old_tag_str'";
				$remark .=".֧��״̬:$old_gp_tag->$in{pay_tag}";
				$is_change=1;
			}
		}
		elsif($old_tag_str=~/(��|��)/){ #��GPƱȥ��GP֧��״̬
			$old_tag_str=~s/(��|��)//g;
			$sql_upt .= ",Tag_str='$old_tag_str'";
		}
		if ($in{old_bank_id} ne $in{pay_by}) {
			$sql_upt .= ",\nPay_bank='$in{pay_by}'";
			$remark .=",֧������(������Ŀ)$in{old_bank_id}-$in{pay_by}:$assist_hash{$in{old_bank_id}}->$assist_hash{$in{pay_by}}";
			$is_change=1;
		}
		if ($Pay_kemu ne $in{Pay_kemu}) {
			$sql_upt .= ",Pay_kemu='$in{Pay_kemu}'";
			$remark .=",�����Ŀ$Pay_kemu->$in{Pay_kemu}";
			$is_change=1;
		}
		if ($in{old_et_price} ne $in{et_price} ) {
			$sql_upt .=",\nET_price=$in{et_price}";	
			$remark .=",֧�����:$in{old_et_price}->$in{et_price}";
			$is_change=1;
		}
		($new_office_id,$b2b_user)=split/-/,$in{office_id},2;
		if ($in{et_type} eq "L") {##B2GûƱ֤��Դ   liangby@2017-12-29
			$new_office_id="";
		}
		if ($office_id ne $new_office_id ) {
			$sql_upt .=",\nOffice_ID='$new_office_id'";
			$remark .=",��Դ:$office_id->$new_office_id";
			$is_change=1;
		}
		if ($in{et_type} eq "B") {
			$sql_upt .=",\n Dev_by='$b2b_user'";
			$remark .=",B2B�˺�:$old_b2b_user->$b2b_user";
			$is_change=1;
		}
		$sql_upt .= ",Account_user='$in{User_ID}'";
	}		
	$sql_upt .= "\nwhere Reservation_ID='$in{Reservation_ID}' \n";
	if ($in{et_type} eq 'Y') {##BSPͬ��֧�����    liangby@2016-12-8
		##ȡ��ͬ��,�п��ܻ��н�������   liangby@2017-12-20
		##$sql_upt .=qq` update ctninfo..Airbook_$Top_corp set  ET_price=(select sum(In_price++isnull(In_tax,0)+isnull(In_yq,0)) from ctninfo..Airbook_detail_$Top_corp where Reservation_ID='$in{Reservation_ID}' ) where Reservation_ID='$in{Reservation_ID}' \n `;
	}
	#-----------------------------------------------------------
	# д��Air_comm_record�۸��޸ļ�¼ fanzy@2013-3-28
	if (($is_refund eq "1" || $is_refund eq "2") && $Corp_center eq "022000") {
		$old_in_total=sprintf("%.2f",$old_in_total);
		$sql_upt.="
		declare \@new_in_total decimal(10,2)
		select \@new_in_total=In_total from ctninfo..Airbook_$Top_corp where Reservation_ID='$in{Reservation_ID}'
		if not ($old_in_total=\@new_in_total)
		begin
		insert into ctninfo..Air_comm_record(Sales_ID,Reservation_ID,Comm_no,Corp_ID,Op_user,Comm_time,Old_agt,New_agt,Action_type)
			select '$Corp_center','$in{Reservation_ID}',isnull(max(Comm_no),0)+1,'$corp_id','$in{User_ID}',getdate(),$old_in_total,\@new_in_total,'Y'
			 from ctninfo..Air_comm_record where Sales_ID='$Corp_center' and Reservation_ID='$in{Reservation_ID}' and Action_type='Y'
		end \n";
	}
	
	if (&Binary_switch($Function_ACL{HSKJ},1,'A')==1) {
		if (($in{Lock_book} eq "Y" && $Tag_str!~/��/) || ($in{Lock_book} eq "" && $Tag_str=~/��/)) {
			my $Tag_strww="";
			if ($in{Lock_book} eq "Y" && $Tag_str!~/��/) {
				$remark .=",δ������������->������������";
				$Tag_strww="+'��'";
				$is_change=1;
			}elsif($in{Lock_book} eq "" && $Tag_str=~/��/) {
				$remark .=",������������->������������";
				$Tag_strww="";
				$is_change=1;
			}
			$sql_upt .=qq` update ctninfo..Airbook_$Top_corp set Tag_str=str_replace(Tag_str,'��',null)$Tag_strww where Reservation_ID='$in{Reservation_ID}' \n `;
		}
	}
	if ($is_change==1) {
		my @rmk_split=&split_hz($remark,252);
		for(my $j=0;$j<scalar(@rmk_split);$j++){
			$rmk_ms=5*$j; ##����ʱ��  liangby@2013-3-21
			$sql_upt .="insert into ophis..Op_rmk values('$in{Reservation_ID}','$Corp_center','$in{User_ID}',dateadd(ms,$rmk_ms,getdate()),'4','A','$rmk_split[$j]','$Corp_ID') \n";
		}
	}
	$sql = $sql_upt;	
#	if($in{User_ID} eq "admin"){
#		print "<pre>$sql";
#		exit;
#	}

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
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
				}
			}
		}
		if ($in{Refresh} eq "N") {
			print qq!<script>
			function bt_ok(){
				window.close();
			}
			</script>!;		
		}
		elsif ($in{Refresh} eq "win") {##���� wfc@2014-12-09
			print &showMessage("ϵͳ��ʾ", "�޸���Ϣ�ɹ�!", "", "", 1, "");
			print qq!<script>
			setTimeout("parent.pmwin('close');", 1500);
			</script>!;
			
		}
		else{
			print qq!<script>
			function bt_ok(){
				window.opener.location.reload();
				window.close();
			}
			</script>!;			
		}
		if ($in{Refresh} ne "win") {
			print "<script>bt_ok();</script>";
		}
	}
	else{
		$db->ct_execute("Rollback Transaction sql_insert");
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
				}
			}
		}
		print MessageBox("ϵͳ��ʾ","����ʧ�ܣ�<br><font color=red>ϵͳ����ѡ��Ķ����Ĳ���ʧ�ܣ�","stop",1);
	}
	exit;
}
elsif ($in{Op} eq "P") {	## д�������¼
	if ($in{i_amount} == 0) {
		print MessageBox("ϵͳ��ʾ","����ʧ�ܣ�<br><font color=red>��������Ϊ 0 ��","stop",1);
		exit;
	}
	my $i_type=$in{i_type};
	my ($hs_id,$cert_corp);
	if ($i_type == 2) {		$hs_id="2:$in{i_dept}";		$cert_corp=$in{i_dept};	}	## ����
	elsif ($i_type == 3) {	## �ͻ�	
		$hs_id="3:$in{i_corp}";		$cert_corp=$in{i_corp};
		if ($in{i_assist} ne "") {	$hs_id=$in{i_assist};	}	## ѡ���˸���������Ŀ
	}	
	elsif ($i_type == 4) {	## ��Ӧ��
		$hs_id=$cert_corp=$in{i_office};
		if (index($hs_id,"4:") == -1) {	$hs_id="4:$in{i_office}";	}
		if ($in{i_assist} ne "") {	$hs_id=$in{i_assist};	}	## ѡ���˸���������Ŀ
	}	
	#elsif ($i_type == 5) {	$hs_id=$in{i_assist};		$i_type=substr($hs_id,0,1);	}	## �ʽ�
	elsif ($i_type == 8) {	$hs_id="8:$in{i_insure}";	$cert_corp=substr($in{i_insure},0,6);	}	## ����
	## ����ƾ֤д��ʱ��office��Ϣ
	$sql="select c.Is_ET,b.Airline_ID
		from ctninfo..Airbook_lines_$Top_corp b,
			ctninfo..Airbook_detail_$Top_corp c
		where b.Reservation_ID='$in{Reservation_ID}' 
			and b.Reservation_ID=c.Reservation_ID 
			and b.Res_serial=c.Res_serial
			and b.Res_serial=0
			and c.Last_name='0' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				my ($et_type,$airline)=@row;
				if ($et_type eq "B" || $et_type eq "C") {	$office_id=$Corp_office;	}	## B2B/B2C��office����Ϊ��Office
			}
		}
	}
	## д��
	$sql = "insert into ctninfo..Airbook_cert_$Top_corp
	   (Corp_ID,Res_ID,Cert_date,Serial_ID,Cert_corp,Cert_type,Debt,
		Account_ID,Project_ID,Amount,Debt_type,Op_user,Op_time,Is_ban,Is_auto,Office_ID)
	   select '$corp_id','$in{Reservation_ID}','$in{Cert_date}',max(Serial_ID)+1,'$cert_corp','$is_refund','$in{i_debt}',
		'$in{i_kemu}','$hs_id',$in{i_amount},'$i_type','$in{User_ID}',getdate(),'N','N','$office_id'
		from ctninfo..Airbook_cert_$Top_corp
		where Cert_date='$in{Cert_date}' and Res_ID='$in{Reservation_ID}' \n";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
			}
		}
	}
	## ����Ƿ�ƽ��
	my $t_total=0;
	$sql = "select Debt,Amount from ctninfo..Airbook_cert_$Top_corp where Cert_date='$in{Cert_date}' and Res_ID='$in{Reservation_ID}'";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				if ($row[0] == 0) {
					$t_total = sprintf("%.2f",$t_total-$row[1]);
				}
				else{
					$t_total = sprintf("%.2f",$t_total+$row[1]);
				}
			}
		}
	}
	if ($t_total==0) {
		$sql = "update ctninfo..Airbook_cert_$Top_corp set Is_ban='Y' where Cert_date='$in{Cert_date}' and Res_ID='$in{Reservation_ID}'";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{					
				}
			}
		}
	}
	print "<form action='air_ban_do.pl' method=post name=book>
	<input type=hidden name=Show value='$in{Show}'>
	<input type=hidden name=Cert_date value='$in{Cert_date}'>
	<input type=hidden name=Reservation_ID value='$in{Reservation_ID}'>
	<input type=hidden name=User_ID value='$in{User_ID}'>
	<input type=hidden name=Serial_no value='$in{Serial_no}'>
	</form>
	<script>
		document.book.submit();
	</script>";
	exit;
}
elsif ($in{Op} eq "D") {	## ɾ��ƾ֤��¼
	$sql = "delete from ctninfo..Airbook_cert_$Top_corp where Cert_date='$in{Cert_date}' and Res_ID='$in{Reservation_ID}' and Serial_ID=$in{Serial_ID}
		update ctninfo..Airbook_cert_$Top_corp set Is_ban='N' where Cert_date='$in{Cert_date}' and Res_ID='$in{Reservation_ID}' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{				
			}
		}
	}
	## ����Ƿ�ƽ��
	my $t_total=0;
	$sql = "select Debt,Amount from ctninfo..Airbook_cert_$Top_corp where Cert_date='$in{Cert_date}' and Res_ID='$in{Reservation_ID}'";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				if ($row[0] == 0) {
					$t_total = sprintf("%.2f",$t_total-$row[1]);
				}
				else{
					$t_total = sprintf("%.2f",$t_total+$row[1]);
				}
			}
		}
	}
	if ($t_total==0) {
		$sql = "update ctninfo..Airbook_cert_$Top_corp set Is_ban='Y' where Cert_date='$in{Cert_date}' and Res_ID='$in{Reservation_ID}'";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{					
				}
			}
		}
	}
	print "<form action='air_ban_do.pl' method=post name=book>
	<input type=hidden name=Show value='$in{Show}'>
	<input type=hidden name=Cert_date value='$in{Cert_date}'>
	<input type=hidden name=Reservation_ID value='$in{Reservation_ID}'>
	<input type=hidden name=User_ID value='$in{User_ID}'>
	<input type=hidden name=Serial_no value='$in{Serial_no}'>
	</form>
	<script>
		document.book.submit();
	</script>";
	exit;
}
elsif ($in{Op} eq "delall") {	## ɾ��ȫ����¼	dabin@2012-03-20
	$sql = "delete from ctninfo..Airbook_cert_$Top_corp where Corp_ID='$corp_id' and Res_ID='$in{Reservation_ID}'
		update ctninfo..Airbook_$Top_corp set Tag_str=str_replace(Tag_str,'!',null) where Reservation_ID='$in{Reservation_ID}' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{				
			}
		}
	}
	print "<form action='air_ban_do.pl' method=post name=book>
	<input type=hidden name=Show value='$in{Show}'>
	<input type=hidden name=Cert_date value='$in{Cert_date}'>
	<input type=hidden name=Reservation_ID value='$in{Reservation_ID}'>
	<input type=hidden name=User_ID value='$in{User_ID}'>
	<input type=hidden name=Serial_no value='$in{Serial_no}'>
	</form>
	<script>
		document.book.submit();
	</script>";
	exit;
}

if ($res_find eq "0") {
	print qq!<center><font color=red>��������Ч������Ȩ�����ö���</font>!;
	#&print_error;
	exit;
}

if ($is_refund eq "1" || $is_refund eq "2") {##�˷�
   $disp_str="style='display:none;'";
}
if ($Tag_str=~/\!/) {
	$ass_js=qq!if (obj == 'C') {
		document.getElementById('box_assist_head').style.display = '';
	}
	else {
		document.getElementById('box_assist_head').style.display = 'none';
	}!;
}
print qq!
<SCRIPT language=JavaScript>
function sh(strtype)	{
	document.all.item(strtype).style.display = "block";
}
function hd(strtype)	{
	document.all.item(strtype).style.display = "none";
}
function Show(obj,obj2,op){
	document.getElementById('A').className = '';
	document.getElementById('B').className = '';
	document.getElementById('C').className = '';
	document.getElementById(obj).className = 'current';
	if (op \!= '') {
		document.operate.Op.value=op;
	}
	hd('A1');	hd('B1');	hd('C1');	sh(obj2);
	$ass_js
}
</SCRIPT>!;

my $comm_name;
if ($comm_method eq "C") {	$comm_name="���ַ���";	}
elsif ($comm_method eq "T") {	$comm_name="���󷵡�";	}
print qq!
<style type="text/css">
	.input_border{border-style:none;}
	.input_border_b{border-style:none;background-color: #e8f4ff;}
	.input_border_h{border-style:none;background-color: #fafafa;}
	.input_border_f{border-style:none;background-color: #fff4c8;}
	.input_border_n{border-style:none;}
</style>
<form method="post" name="operate" value="air_ban_do.pl" onsubmit="return button_onclick();">
<table border=0 width=100% cellpadding=1 cellspacing=1 bgcolor=white  height=100%>
$ban_show
<tr bgcolor=f0f0f0><td>
	<table border=0 width=100% cellpadding=0 cellspacing=0 bgcolor=fffff0>
	<tr>
	<td width=250 height=22><b>�� �� �ţ�<a href="javascript:Show_book('$in{Reservation_ID}');"><font color=maroon>$in{Reservation_ID}</font></a></td>
	$disp_old
	<td width=210>������¼��$booking_ref</td>
	<td width=120>״̬��<a href="javascript:Show_his('$in{Reservation_ID}');">$bk_status</font></a>$comm_name</td>
	</tr></table>
</td></tr>
</table>

<table border=0 width=100% cellpadding=0 cellspacing=0 bgcolor=white class="mainborder">
!;

my $t_str;
if ($Pay_version eq "1") {	## ��ʾƾ֤��¼
	if ($Tag_str!~/\!/) {
		my $is_cert;	
		$sql = "select count(*) from ctninfo..Airbook_cert_$Top_corp where Res_ID='$in{Reservation_ID}' ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$is_cert=$row[0];
				}
			}
		}
		if ($is_cert > 0) {
			$Tag_str .= "!";
			$sql = "update ctninfo..Airbook_cert_$Top_corp set Tag_str=Tag_str+'!' where Reservation_ID='$in{Reservation_ID}' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
					}
				}
			}
		}
	}

	if ($Tag_str=~/\!/) {
		my $c_href = qq!<a href="javascript:Show('C','C1','P');">!;
		if ($Corp_type eq "T") {
			$t_str=qq!<li id='C'>$c_href\���ƾ֤��¼</a></li>!;
		}
		else{	
			$t_str=qq!<span id='C'></span>!;
		}
	}
	else{
		$t_str=qq!<span id='C'></span>!;
	}
}
my $a_href = qq!<a href="javascript:Show('A','A1','W');">!;
my $b_href = qq!<a href="javascript:Show('B','B1','');">!;
print qq!
<tr>
	<td>
		<table border=0 cellpadding=2 cellspacing=0 style="float:right;">
			<tr>
				<td style="color:red;">ͳһ�޸�����</td>!;
				if ($Lock_off eq "Y") {
					print qq!
					<td width="60"><input type="text" name="tk_fid" id="tk_fids" size="10" $Lock_sreadonly/>
					</td>!;
				}else{
					print qq!
					<td width="60"><input type="text" name="tk_fid" id="tk_fids" size="10" maxlength="10" style="position:relative;margin-top:0px;-margin-top:-1px;margin-left:0px;width:30px;z-index:10;border-right:none; background:none;" onblur='change_inprice(this.value);' />
					<span style="border:0px;"><iframe id="fid_filter" frameborder="0" scrolling="no" height="19" style="position:absolute;margin-left:-40px;width:33px;height:19px;z-index:4;overflow:hidden;"></iframe><select id="fid_list" style="position:absolute;margin-left:-40px;-margin-top:1px;width:53px;z-index:2;" onchange="cg_addr();"></select></span></td>!;
				}
				print qq!
			</tr>
		</table>
		<ul class="tabs headertabs">
			<li id='A' class='current'>$a_href\����Ѻ���</a></li>
			<li id='B'>$b_href\������¼</a></li>
			$t_str
		</ul>
	</td>
</tr>
!;	

$print_table .=  qq!<tr id='A1'><td>

<table width=100% border=0 cellpadding=1 cellspacing=0 bgcolor=fffff0>!;
if ($use_extra_inprice eq "Y") {
	$cols_str=" colspan=7";
}else{
	$cols_str=" colspan=5";
}
my $a_hd = qq!<tr bgcolor=f0f0f0 align=center>		
	<td height=20>����</td>
	<td>�����</td>
	<td>��λ</td>
	<td>����</td>
	<td colspan=2>����</td>
	<td>���</td>
	<td>����</td>
	<td>����</td>
	<td $cols_str>��ͣ</td>
	<td>&nbsp;</td>
	</tr>!;

my @departure = ();
my @arrival = ();
$sql = qq!select distinct a.IsReturn,rtrim(a.Airline_ID+a.Flight_no),
		convert(char(10),a.Air_date,102),a.Departure,a.Arrival,a.Depart_time,
		a.Arrive_time,a.Equipment,a.NumOfStops,e.Seat_type,a.Airline_ID
	FROM ctninfo..Airbook_lines_$Top_corp a, 		
		ctninfo..Airbook_detail_$Top_corp e
	WHERE a.Reservation_ID = e.Reservation_ID
		and a.Res_serial = e.Res_serial
		and a.Sales_ID='$Corp_center' 
		and e.Sales_ID='$Corp_center' 
		and a.Reservation_ID = '$in{Reservation_ID}'
		and e.Reservation_ID = '$in{Reservation_ID}'
	order by a.Res_serial !;
my @airlines=();
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT) {
		while(@row = $db->ct_fetch) {				
			push(@airlines,"$a_hd<tr bgcolor=f8f8f8 align=center>
			<td align=left height=18><font color=red>$row[2]</td>
			<td>$row[1]</td>
			<td>$row[9]</td>
			<td>$row[3]</td>
			<td colspan=2>$row[4]</td>
			<td>$row[5]</td>
			<td>$row[6]</td>			
			<td>$row[7]</td>
			<td $cols_str>$row[8]</td><td>&nbsp;</td></tr>\n");
			push(@departure, $row[3]);
			push(@arrival, $row[4]);
			$air_code=$row[10];
		}
	}
}

$colspan_num=14;
if ($use_extra_inprice eq "Y") {
	$colspan_num=17;
}
$i=0;	$person_num=0;	$serial='';
my $tk_in_price = 0;
my $ticket_total=0;
$guest_tax_total=0;
my $out_total=$in_total=$agt_total=$profit=$agt_comm=$profit_up=0;
#row28
$sql = "select a.First_name,rtrim(a.Last_name),a.Passage_type,a.Seat_type,a.Having_babe,
		a.In_price,a.Out_price,a.Insure_type,a.Insure_inprice,a.Insure_outprice,
		a.Insure_num,a.Res_serial,a.Origin_price,a.Ticket_ID,a.In_discount,a.Agt_discount,
		a.Insure_agtprice,a.Last_name,a.Tax_fee+a.YQ_fee,a.Recv_price,a.SCNY_price,
		rtrim(a.Insure_mode),a.Is_ET,rtrim(a.Air_code),a.Ticket_LID,rtrim(a.Insure_no),Return_spfee,Return_price,Isnull(Extra_inprice,0),
		isnull(a.In_disrate,0),isnull(a.In_tax,a.Tax_fee),isnull(a.In_yq,a.YQ_fee),isnull(a.In_fee,0)  
	from ctninfo..Airbook_detail$tbook a
	where a.Reservation_ID = '$in{Reservation_ID}'				
	order by a.Res_serial,convert(tinyint,a.Last_name)" ;
#print "<pre>$sql</pre>";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT) {
		while(@row = $db->ct_fetch) {
			## �۸���ʾ�޸�
			my $scny_str;
			#if ($air_type eq "Y") {##����
				$scny_str="<td>SCNY</td>";
			#}
			if ($serial ne $row[11]) {
				$serial = $row[11];	
				if ($serial > 0) {
					$print_table .= "<script>
					function change_all_$ck_num(){
						if (document.operate.ck_$ck_num.checked) {
							$change_tkt	
							var in_total = 0;
							var scny_total=0;
							for (var j=0; j < in_price.length; j++){
								in_total = in_total + in_price[j];
								scny_total=scny_total+scny_price[j];
							}
							in_total = in_total*1 + Math.round(document.operate.tax_total.value)
							scny_total = scny_total*1 + Math.round(document.operate.tax_total.value)
							document.operate.in_total.value = Round(in_total,$Dec_round_2);
							document.operate.scny_total.value = Round(scny_total,$Dec_round_2);
							document.operate.profit.value = parseFloat(document.operate.scny_total.value - document.operate.in_total.value).toFixed($Dec_round_2);
							cal_total();
						}
					}
					</script>";
					my $ckoname=($use_extra_inprice eq "Y")?"���ⲿ�����":"";
					$ckoname.=($air_type eq "Y" && $is_refund eq "0")?"���󷵵���":"";
					if ($Lock_off ne "Y") {
						$print_table .= "<tr bgcolor=f0f0f0><td colspan=$colspan_num height=20 align=right><input type=checkbox name=ck_$ck_num onclick='change_all_$ck_num();'><font color=red>ͳһ���Ϻ�������SCNY���׼�$ckoname</td></tr>";
					}
				}
				$change_tkt = "";		$ck_num ++;			$j = 0;	
				$print_table .=  $airlines[$serial];				
				$print_table .=  qq!<tr align=center bgcolor=f0f0f0>
				<td height=20>����</td>	
				<td>Ʊ��</td>
				<td nowrap>��Ʊ��</td>
				<td nowrap>Ʊ���</td>
				<td>˰</td>!;
				if ($air_type eq "Y") {
					$print_table .="<td>����˰</td>";
				}else{
					$print_table .="<td>����<br>����˰</td><td>����<br>ȼ�ͷ�</td>";
				}
				$print_table .=qq!
				<td>��������</td>
				<td>����</td>
				$scny_str
				<td>�����</td>				
				<td>�׼�</td>!;
				if ($use_extra_inprice eq "Y") {
					$print_table .=qq!<td>�ⲿ����</td>!;
				}
				
				if ($air_type eq "Y" && $is_refund eq "0") {
				$print_table .=  qq!
				<td>�󷵵���</td>
				<td>������</td>!;
				}
				$print_table .=  qq!
				<td>ͬ�м�</td>
				<td>����</td>
				<td nowrap>����</td>
				</tr>\n!;
			}
			
			my $i_price=$row[5];		my $o_price=int($row[6]);	my $a_price = $row[12];
			my $in_dis = $row[14];		my $agt_dis=$row[15];		my $in_num = $row[10];
			my $scny_price =$row[20];	$et_type=$row[22];	
			my $Extra_inprice=$row[28];  ##�ⲿ�����   liangby@2015-2-12
			my $In_disrate=$row[29];  ##��������   liangby@2016-7-21
			if ($In_disrate ne "" && $In_disrate !=0) {
				$ck_usedisrate=" checked ";
			}
			my $In_tax=$row[30]; my $In_yq=$row[31]; my $In_fee=$row[32];
			#���ʺ�
			my $i_up_price_dis=$row[26]; #�󷵵���   
			my $i_up_price=$row[27]; #�󷵽��
			if ($i_up_price_dis eq "") {$i_up_price_dis="0.00";			}
			if ($scny_price eq "") {
				$scny_price=0;
			}
			if ($Pay_version ne "1") {	$bank_id=$row[21];	}
			$ticket_total = $ticket_total + $o_price;
			push(@in_price,$i_price);	push(@out_price,$o_price);	push(@agt_price,$a_price);
			push(@up_price,$i_up_price); push(@scny_price,$scny_price);
			if ($row[2] eq "A" || $row[2] eq "C") {	## ���㵥������	dabin@2011-1-4
				$s_profit{$row[1]}+=$o_price-$i_price;
			}
			if ($tk_in_price==0) {
				$tk_in_price = $in_dis;
			}
			
			$agt_cal .= "document.operate.tk_agt_$i.value = agt_price[$i]; ";
			$out_total += $o_price;		$in_total += $i_price;		$agt_total += $a_price;
			$scny_total +=$scny_price;
			$profit += $scny_price-$i_price;			$agt_comm += $o_price-$a_price;
			$profit_up += $i_up_price;
			$tax_total = $tax_total + $row[30]+$row[31] ;
			$guest_tax_total +=$row[18];
			if ($j == 0) {	$ck_top=$i;}
			my $type_aircode = $row[23] eq '' ? 'text' : 'hidden';
			$type_aircode="";  ##�����޸ĳ�Ʊ���룬��Ϊ��Щ�����Ǵ�ģ�MU��BSP��b2b���п��ܲ�һ��   liangby@2013-4-9
			if ($row[24] eq "") {	$row[24] = 0;	}
			
			if ($i eq "0") {  #�Զ����Ʊ�źʹ�ӡ���� wfc 2013-02-18
				$tk_js = " onchange='auto_tknum();'";
				$ltk_js = " onchange='auto_tknum();'";
				$printno_js = " onchange='auto_printno();'";
			}else{
				$tk_js = "";
				$ltk_js = "";
				$printno_js = "";
			}
			$print_table .=  qq`<tr bgcolor=white align=center>
			<td align=left>$row[0]<input type=hidden name=id_$i value='$row[11],$row[17]'>
			<input type=hidden name=cust_name_$i value='$row[0]'></td>
			<td align=left nowrap><input type="$type_aircode" name="aircode_$i" id="aircode_$i" value="$row[23]" size="2" $p_read maxlength="3" old_value="$row[23]" />-
				<INPUT name=tk_num_$i  id=tk_num_$i maxlength=10 onKeypress="if ((event.keyCode < 45 || event.keyCode > 57) && !('$Corp_center'=='022000' && (event.keyCode==74 || event.keyCode==106))) event.returnValue = false;" size=10 $p_read $tk_js value='$row[13]' onkeyup="Get_ticket_id(this,1);" tktid=''>
				<input type="text" name="tk_lnum_$i" id="tk_lnum_$i" value="$row[24]" size="4" $p_read maxlength="6" $ltk_js/></td>
			<td><input type="text" name="print_no_$i" idname="print_no_$i" value="$row[25]" size="2" $p_read maxlength="3" $printno_js/></td>\n`;
			my $t_o_price=$o_price;
			if ($air_type eq "Y" && $Corp_center eq "CAN378") {
				$t_o_price=$scny_price;
			}
			my $tid;	if ($row[11] == 0) {	$tid=" tid='$row[13]'";	}
			$print_table .=  qq!<td align=right><font color=navy>$o_price <input type=hidden name="tk_out_$i" value="$t_o_price" /></td>
				<td align=right>$row[18]<input type=hidden name="tax_$i" id="tax_$i" value="$row[18]"/></td>!;
			#cal_tax
			if ($air_type eq "Y") {
				$print_table .=qq!<td align=right><input type=text name="tk_intax_$i" id="tk_intax_$i" value="$In_tax" onblur="cal_tax($i);" $p_read size=7  $Lock_sreadonly/>
					<input type=hidden name="tk_inyq_$i" id="tk_inyq_$i" value="$In_yq" /></td>!;
			}else{
				$print_table .=qq!<td align=right><input type=text name="tk_intax_$i" id="tk_intax_$i" value="$In_tax" onblur="cal_tax($i);" $p_read size=7  $Lock_sreadonly/></td>
					<td align=right><input type=text name="tk_inyq_$i" id="tk_inyq_$i" value="$In_yq" $p_read size=7  onblur="cal_tax($i);" $Lock_sreadonly/></td>!;
			}
	
			$print_table .=qq!
				<td><input type="text" name="in_fee_$i" id="in_fee_$i" value="$In_fee" $p_read size=7  $Lock_sreadonly/></td>
				<td><input type="text" name="in_dis_$i" id="in_dis_$i" $disp_str size="5" class="readonly" value="$in_dis" $tid  $Lock_sreadonly/></td>
				\n!;
			my $r_price = int($row[19]);
			my $price = $o_price + $row[18] - $r_price;
			my $Agent_price = sprintf("%.2f",$scny_price-$i_price);
			my $Up_price_disjs=($air_type eq "Y" && $is_refund eq "0")?"cal_up($i,this);":"";
			#if ($air_type eq "Y") {##����
				$print_table .=  qq!<td><input type=text name="tk_scny_$i" id="tk_scny_$i" onblur="cal_tkscny($i);$Up_price_disjs" value="$scny_price" $p_read size=7  $Lock_sreadonly/></td></td>!;
			#}
			$print_table .=  qq!<td><input type="text" name="Agent_price_$i" id="Agent_price_$i" onblur="cal_tk_comm($i,this);$Up_price_disjs" value="$Agent_price" size="6" $p_read  $Lock_sreadonly/></td>
				<td><INPUT name="tk_in_$i" id="tk_in_$i"  size=7 $p_read onblur="cal_tkin($i);$Up_price_disjs" value=$i_price $Lock_sreadonly>!;
			if ($use_extra_inprice eq "Y") {	##���ⲿ�����	
				$print_table .=qq!</td><td><input type="text" name="Extra_inprice_$i" id="Extra_inprice_$i" size=7 $p_mod_extra value="$Extra_inprice"  $Lock_sreadonly/></td>	
				\n!;
				$change_tkt .=" document.operate.Extra_inprice_$i.value=document.operate.Extra_inprice_$ck_top.value; ";
			}
				
			if ($air_type eq "Y" && $is_refund eq "0") {
			#���ʺ󷵴���
			$print_table .=  qq!<td><INPUT type=text name=Up_price_dis_$i  id="Up_price_dis_$i" onblur="cal_up($i,this);" size=6 value='$i_up_price_dis' $p_read  $Lock_sreadonly></td>
				                <td><INPUT type=text name="Up_price_$i" size=6 id="Up_price_$i" onblur="cal_tk_up($i,this);" value='$i_up_price' $p_read  $Lock_sreadonly></td>!;
				$change_tkt .= "document.operate.Up_price_dis_$i.value=document.operate.Up_price_dis_$ck_top.value;document.operate.Up_price_dis_$i.onblur();\n";
			}
			$change_tkt .= "document.operate.in_dis_$i.value=document.operate.in_dis_$ck_top.value;\n";
			$change_tkt .= "document.operate.tk_in_$i.value=document.operate.tk_in_$ck_top.value;\n";
			$change_tkt .= "document.operate.Agent_price_$i.value=document.operate.Agent_price_$ck_top.value;\n";
			$change_tkt .= "in_price[$i] = Round(document.operate.tk_in_$ck_top.value,$Dec_round_2); ";
			$change_tkt .= "document.operate.tk_scny_$i.value=document.operate.tk_scny_$ck_top.value;\n";
			$change_tkt .=" scny_price[$i]=Round(document.operate.tk_scny_$ck_top.value,$Dec_round_2); ";

			my $Insure="";
			if($in{Type} eq "A"){	
				if($row[7]  eq "N")	{ $Insure="����"; }	else{ 
					if ($in_num > 0) {	$Insure="$row[8]��$in_num"; }	else{	$Insure="����";	}
				}	
			}
			else{	
				if($row[7]  eq "N")	{ $Insure="����"; }
				if($row[7]  eq "F")	{ $Insure="�͡�$in_num"; }
				if($row[7]  eq "Y")	{ 
					if ($in_num > 0) {	$Insure="$row[9]��$in_num";	$price=$price+$row[9]*$in_num;	}	
					else{	$Insure="����";	}
				}
			}
		
			push(@recv_price,$price);	
			push(@scny_price_r,$scny_price);
			my $net_profit = $a_price-$i_price;
			$print_table .=  qq!
				<td>$a_price<INPUT type=hidden name=tk_agt_$i size=6 value=$a_price></td>
				<td><input type="text" name="net_profit_$i" id="net_profit_$i" $disp_str size="4" class="readonly" value="$net_profit" $Lock_sreadonly/></td>
				<td align=right><font color=blue>$Insure
				<input type="hidden" name="depart_$i" value="$departure[$serial]" />
				<input type="hidden" name="arrive_$i" value="$arrival[$serial]" />
				<input type="hidden" name="old_indisrate_$i" id="old_indisrate_$i" value="$In_disrate" /></td></tr>!;
			$i++;
			$j++;
			$person_num ++;
		}
	}
}
$print_table .= "<script>
function change_all_$ck_num(){
	if (document.operate.ck_$ck_num.checked) {
		$change_tkt	
		var in_total = 0;
		var scny_total=0;
		for (var j=0; j < in_price.length; j++){
			in_total = in_total + in_price[j];
			scny_total=scny_total+scny_price[j];
		}
		in_total = in_total*1 + Math.round(document.operate.tax_total.value)
		scny_total = scny_total*1 + Math.round(document.operate.tax_total.value)
		document.operate.in_total.value = Round(in_total,$Dec_round_2);
		document.operate.scny_total.value = Round(scny_total,$Dec_round_2);
		document.operate.profit.value = parseFloat(document.operate.scny_total.value - document.operate.in_total.value).toFixed($Dec_round_2);
		cal_total();
	}
}

function auto_tknum(){
	var t_num = document.operate.T_num.value;
	var tk_diff = 0;
	if (t_num>1) {
		var tk_lno = document.getElementById('tk_lnum_0').value;
		var tk_no = document.getElementById('tk_num_0').value;
		var no_num = tk_no.substr(tk_no.length-tk_lno.length,tk_lno.length);
		if (no_num>tk_lno && tk_lno>0) {
			var temp_num;
			temp_num = parseInt(tk_no.substr(tk_no.length-tk_lno.length-1,1))+1;
			temp_num = temp_num.toString();
			tk_lno = temp_num + tk_lno;
			document.getElementById('tk_lnum_0').value = tk_lno;
		}
		if (tk_lno>0) {
			tk_diff = parseInt(tk_no.substr(0,tk_no.length-tk_lno.length)+tk_lno)-parseInt(tk_no)
		}
		for (var i=1;i<t_num ;i++) {
			var j=i-1;
			var tk_no_tmp = parseInt(document.getElementById('tk_num_'+j).value)+tk_diff+1;
			tk_no_tmp = tk_no_tmp.toString();
			document.getElementById('tk_num_'+i).value=tk_no_tmp;
			if (tk_lno>0) {
				var tk_lno_tmp = parseInt(tk_no_tmp)+tk_diff;
				tk_lno_tmp = tk_lno_tmp.toString();
				no_num = tk_lno_tmp.substr(tk_lno_tmp.length-tk_lno.length,tk_lno.length);
				if (parseInt(no_num)==0) {
					var temp_num;
					temp_num = parseInt(tk_no_tmp.substr(tk_no_tmp.length-no_num.length-1,1))+1;
					no_num = temp_num + no_num;
				}
				document.getElementById('tk_lnum_'+i).value=no_num;
			}else{
				document.getElementById('tk_lnum_'+i).value='';
			}
		}
	}
}
function auto_printno(){
	var t_num = document.operate.T_num.value;
	if (t_num>1) {
		var print_no= document.getElementById('print_no_0').value;
		for (var i=1;i<t_num ;i++) {
			document.getElementById('print_no_'+i).value=print_no;
		}
	}
}
</script>";
my $ckoname=($use_extra_inprice eq "Y")?"���ⲿ�����":"";
$ckoname.=($air_type eq "Y" && $is_refund eq "0")?"���󷵵���":"";
if ($Lock_off ne "Y") {
$print_table .= qq!<tr bgcolor=f0f0f0>
	<td colspan=$colspan_num height=20 align=right><label for="Usedisrate"><input type=checkbox name=Usedisrate id="Usedisrate" value="Y" $ck_usedisrate />��������</label>&nbsp; &nbsp;<input type=checkbox name=ck_$ck_num onclick='change_all_$ck_num();'><font color=red>ͳһ���Ϻ�������SCNY���׼�$ckoname</td>
</tr>\n!;
}

$in_price = join(",",@in_price);
$agt_price = join(",",@agt_price);
$scny_price = join(",",@scny_price);
$up_price = join(",",@up_price);

$recv_price = join(",",@recv_price);
$scny_price=join(",",@scny_price_r);
#print "in $in_price<br>agt $agt_price<br>out $scny_price";
$in_price = "var in_price = new Array($in_price,0);";
$agt_price = "var agt_price = new Array($agt_price,0);";
#if ($air_type eq "Y" && $Corp_center eq "CAN378") {##������SCNY����
$scny_price = "var scny_price = new Array($scny_price,0);";
#}else{
#	$scny_price = "var scny_price = new Array($scny_price,0);";
#}
$recv_price = "var recv_price = new Array($recv_price,0);";

$up_price = "var up_price = new Array($up_price,0);";
##����֧�����     likh@2010-3-29
$dis_etprice="";

$print_table .=  qq@<script>
	$in_price
	$agt_price
	$scny_price
	$recv_price
	$up_price
	function change_in(i,selobj){	
		in_price[i] = Round(selobj.value,$Dec_round_2);
		var in_total = 0;
		for (var j=0; j < in_price.length; j++){
			in_total = in_total + in_price[j];
		}
		in_total = in_total + Math.round(document.operate.tax_total.value);
		document.operate.in_total.value = Round(in_total,$Dec_round_2);
		var in_dis_num=(((scny_price[i]-in_price[i])/scny_price[i])*100).toFixed(1);
		document.getElementById('in_dis_' + i).value=in_dis_num;
		document.operate.profit.value = parseFloat(document.operate.scny_total.value - in_total).toFixed($Dec_round_2);
		cal_total();
	}	
	function Round(a_Num , a_Bit)  {
	  return (Math.round(a_Num * Math.pow (10 , a_Bit)) / Math.pow(10 , a_Bit));
	}

	function cal_in(i,selobj){
		var pnum = $person_num;
		var discount = selobj.value;
		var format3=/^[0-9]+\\.?[0-9]{0,2}\$/g;
		if (!format3.test(discount)) {
			   alert("���߸�ʽ��Ч");
			   selobj.focus();
			   return;
		}
		if (discount == 0) {
			in_price[i] = scny_price[i];
		}
		else{
			//in_price[i] = Math.round(scny_price[i]-(scny_price[i]*0.03+scny_price[i]*0.97*(discount-3)/100));
			in_price[i] = Round(scny_price[i]-scny_price[i]*discount/100,$Dec_round_2);
		}
		document.getElementById('tk_in_' + i).value = in_price[i];
		document.getElementById('Agent_price_' + i).value = Round(scny_price[i]-in_price[i],$Dec_round_2);
		document.getElementById('net_profit_' + i).value = Round(agt_price[i]-in_price[i],$Dec_round_2);

		var in_total = 0;
		for (var j=0; j < in_price.length; j++){
			in_total = in_total + in_price[j];
		}
		in_total = in_total + Math.round(document.operate.tax_total.value);
		document.operate.in_total.value = Round(in_total,$Dec_round_2);
		document.operate.profit.value = Round(document.operate.scny_total.value - in_total,$Dec_round_2);
		
		cal_total();
	}

	function change_inprice(val) {
		var pnum = $person_num;
		if (val == '') {
			return false;
		}
		for (var j = 0; j < pnum; j++) {
			document.getElementById('in_dis_' + j).value = val;
			cal_in(j, document.getElementById('in_dis_' + j));
			//alert(val);
		}
	}
	function cal_tkscny(i){
		var selobj=document.getElementById('tk_in_' + i);
		var old_indisrate=document.getElementById('old_indisrate_' + i).value;
		numberformat(selobj);
		scny_price[i]=1*document.getElementById('tk_scny_' + i).value;
		var agent_price=document.getElementById('Agent_price_' + i).value;
		var in_total = 0;
		var scny_total=0;
		var in_dis_num=0;
		
		if (document.getElementById("Usedisrate").checked) {//����
			in_price[i] = Round((scny_price[i]-agent_price*1),$Dec_round_2);
			document.getElementById('tk_in_' + i).value=in_price[i];
			in_dis_num=(scny_price[i]==0)?0:((agent_price/scny_price[i])*100).toFixed(1);
		}else{
			in_price[i] = Round(selobj.value,$Dec_round_2);
			
			document.getElementById('Agent_price_' + i).value = Round(scny_price[i]-selobj.value,$Dec_round_2);
			in_dis_num=(scny_price[i]==0)?0:(((scny_price[i]-in_price[i])/scny_price[i])*100).toFixed(1);
		}
		
		for (var j=0; j < in_price.length; j++){
			in_total = in_total + in_price[j];
			scny_total=scny_total+scny_price[j];
		}
		
		document.getElementById('in_dis_' + i).value=in_dis_num;
		in_total = in_total + Math.round(document.operate.tax_total.value);
		scny_total=scny_total+Math.round(document.operate.tax_total.value);
		document.operate.in_total.value = Round(in_total,$Dec_round_2);
		document.operate.scny_total.value = Round(scny_total,$Dec_round_2);
		document.operate.profit.value = Round(document.operate.scny_total.value - in_total,$Dec_round_2);
		cal_total();
	}
	function cal_tkin(i){
		var selobj=document.getElementById('tk_in_' + i);
		var old_indisrate=document.getElementById('old_indisrate_' + i).value;
		numberformat(selobj);
		scny_price[i]=1*document.getElementById('tk_scny_' + i).value;
		var agent_price=document.getElementById('Agent_price_' + i).value;
		var in_total = 0;
		var scny_total=0;
		var in_dis_num=0;
		if (document.getElementById("Usedisrate").checked) {//����
			in_price[i] = Round(selobj.value,$Dec_round_2);
			scny_price[i] = Round((in_price[i]+agent_price*1),$Dec_round_2);
			in_dis_num=(scny_price[i]==0)?0:((agent_price/scny_price[i])*100).toFixed(1);
			document.getElementById('tk_scny_' + i).value=scny_price[i];
		}else{
			in_price[i] = Round(selobj.value,$Dec_round_2);
			
			document.getElementById('Agent_price_' + i).value = Round(scny_price[i]-selobj.value,$Dec_round_2);
			in_dis_num=(scny_price[i]==0)?0:(((scny_price[i]-in_price[i])/scny_price[i])*100).toFixed(1);
		}
		
		for (var j=0; j < in_price.length; j++){
			in_total = in_total + in_price[j];
			scny_total=scny_total+scny_price[j];
		}
		
		
		document.getElementById('in_dis_' + i).value=in_dis_num;
		in_total = in_total + Math.round(document.operate.tax_total.value);
		scny_total=scny_total+Math.round(document.operate.tax_total.value);
		document.operate.in_total.value = Round(in_total,$Dec_round_2);
		document.operate.scny_total.value = Round(scny_total,$Dec_round_2);
		document.operate.profit.value = Round(document.operate.scny_total.value - in_total,$Dec_round_2);
		cal_total();
	}
	function cal_tax(i){
		var tax_total=0;
		for (var j=0; j < in_price.length-1; j++){
			tax_total =tax_total+1*document.getElementById('tk_intax_'+ j).value+1*document.getElementById('tk_inyq_' + j).value;
		}
		document.getElementById('tax_total').value=tax_total;
		cal_tkscny(i);
	}
	function cal_up(i,selobj){
		numberformat(selobj);
		document.getElementById('Up_price_' + i).value = Round(in_price[i]*(document.getElementById('Up_price_dis_' + i).value/100),$Dec_round_2);
		var up_total = 0;	
		for (var j=0; j < up_price.length-1; j++){
			up_price[j]=Round(document.getElementById('Up_price_' + j).value,$Dec_round_2);
			up_total = up_total + up_price[j];//Round(document.getElementById('Up_price_' + j).value,$Dec_round_2) ;	
		}
		document.operate.profit_up.value = up_total;		
	}
	function cal_tk_up(i,selobj){
		numberformat(selobj);
		up_price[i] = Round(selobj.value,$Dec_round_2);
		var up_total = 0;
		for (var j=0; j < up_price.length; j++){
			up_total = up_total + up_price[j];
		}
		document.operate.profit_up.value = Round(up_total,$Dec_round_2);
	}
	function cal_tk_comm(i,selobj){
		numberformat(selobj);
		in_price[i] = Round(scny_price[i]-selobj.value,$Dec_round_2);
		var in_total = 0;
		for (var j=0; j < in_price.length; j++){
			in_total = in_total + in_price[j];
		}
		document.getElementById('tk_in_' + i).value=in_price[i];
		var in_dis_num=(scny_price[i]==0)?0:(((scny_price[i]-in_price[i])/scny_price[i])*100).toFixed(1);
		in_dis_num=in_dis_num*1;
		document.getElementById('in_dis_' + i).value=in_dis_num;
		in_total = in_total + Math.round(document.operate.tax_total.value);
		document.operate.in_total.value = Round(in_total,$Dec_round_2);
		document.operate.profit.value = Round(document.operate.scny_total.value - in_total,$Dec_round_2);
		cal_total();
	}
	function cal_total(){	
		document.operate.agt_comm.value = Math.round(document.operate.scny_total.value - document.operate.in_total.value);
		document.operate.profit_net.value = Round(1*document.operate.agt_total.value - 1*document.operate.in_total.value,$Dec_round_2);
		//$dis_etprice
	}
	function cg_addr(){
		var prod=document.getElementById('fid_list').options[document.getElementById('fid_list').selectedIndex].text;
		document.getElementById('tk_fids').value = prod;
		document.getElementById('tk_fids').onblur();
	}
</script>@;

if ($recv_total eq "")	{	$recv_total=$agt_total;	}
$in_total += $tax_total;	$agt_total += $guest_tax_total;	$out_total += $guest_tax_total;
$scny_total +=$tax_total;
$agt_comm=sprintf("$Dec_round",$agt_comm);
$profit=sprintf("$Dec_round",$profit);
$profit_up=sprintf("$Dec_round",$profit_up);
$profit_net = sprintf("$Dec_round",$agt_total - $in_total);
$print_table .=  qq!<tr><td bgcolor=808080 colspan=$colspan_num height=1></td></tr>
<tr bgcolor=white>
	<td colspan="5"></td>
	<td colspan="12">
		<table border=0 cellpadding=2 cellspacing=0 width=100%>
		<tr align=center bgcolor=f0f0f0>
			<td bgcolor=white height=20></td>
			<td>����</td>
			<td>SCNY</td>
			<td>����</td>
			<td>�����</td>!;
			if ($air_type eq "Y" && $is_refund eq "0") {
				$print_table .=  qq!<td>������</td>!;
			}		
		$print_table .=  qq!
			<td>����</td>
		</tr>
		<tr align=right>
		<td height=24>�ϼ�<input type=hidden name=tax_total id="tax_total" value=$tax_total></td>
		<td><INPUT name=out_total readOnly size=12 style="border-bottom-color:gray;border-bottom-width: 1px;BORDER-LEFT: medium none; BORDER-RIGHT: medium none; BORDER-TOP: medium none; TEXT-ALIGN: right" value=$out_total></td>
		<td><INPUT name=scny_total readOnly size=12 style="border-bottom-color:gray;border-bottom-width: 1px;BORDER-LEFT: medium none; BORDER-RIGHT: medium none; BORDER-TOP: medium none; TEXT-ALIGN: right" value=$scny_total></td>
		<td><INPUT name=in_total readOnly size=12 style="border-bottom-color:gray;border-bottom-width: 1px;BORDER-LEFT: medium none; BORDER-RIGHT: medium none; BORDER-TOP: medium none; TEXT-ALIGN: right" value=$in_total></td>
		<td style='display:none;'><INPUT name=agt_comm readOnly size=12 style="border-bottom-color:gray;border-bottom-width: 1px;BORDER-LEFT: medium none; BORDER-RIGHT: medium none; BORDER-TOP: medium none; TEXT-ALIGN: right" value=$agt_comm></td>
		<td style='display:none;'><INPUT name=agt_total readOnly size=12 style="border-bottom-color:gray;border-bottom-width: 1px;BORDER-LEFT: medium none; BORDER-RIGHT: medium none; BORDER-TOP: medium none; TEXT-ALIGN: right" value=$agt_total></td>
		<td><INPUT name=profit readOnly size=7 style="border-bottom-color:gray;border-bottom-width: 1px;BORDER-LEFT: medium none; BORDER-RIGHT: medium none; BORDER-TOP: medium none; TEXT-ALIGN:right;" value=$profit></td>!;
		if ($air_type eq "Y" && $is_refund eq "0") {
		$print_table .=  qq!
		<td><INPUT name=profit_up readOnly size=7 style="border-bottom-color:gray;border-bottom-width: 1px;BORDER-LEFT: medium none; BORDER-RIGHT: medium none; BORDER-TOP: medium none; TEXT-ALIGN:right;" value=$profit_up></td>!;
		}
		$print_table .=  qq!
		<td><INPUT name=profit_net readOnly size=7 style="border-bottom-color:gray;border-bottom-width: 1px;BORDER-LEFT: medium none; BORDER-RIGHT: medium none; BORDER-TOP: medium none; TEXT-ALIGN:right;" value=$profit_net></td>
		</tr>
		</table>
	</td>
</tr>
<tr><td bgcolor='#B8DFFF' colspan=$colspan_num height=1></td></tr>
!;
print $print_table;

my $tkt_type_list=qq`<select name="et_type" id="et_type" onchange="mod_tkt(this.options[this.options.selectedIndex].value)" style="width:50px;" $lock_disd>\n`;
for (my $i=0;$i<scalar(@tkt_type);$i++) {
	my $t_sel;
	if ($et_type eq $tkt_type[$i]{Type_ID}) {	$t_sel = "selected";	}
	if ($tkt_type[$i]{Type_ID} eq "W") {
		$tkt_type_list.="<option value='$tkt_type[$i]{Type_ID}' style='color:red;' $t_sel>$tkt_type[$i]{Type_name}</option>\n";
	}
	else{
		$tkt_type_list.="<option value='$tkt_type[$i]{Type_ID}' $t_sel>$tkt_type[$i]{Type_name}</option>\n";
	}
}
$tkt_type_list .= "</select>";

## ���� jeftom @2010-12-6
if ($old_tkt_time ne "" && $If_out ne "3") {##�ѳ�Ʊ�Ķ������������޸�Ʊ֤����             liangby@2009-9-8
	my $tks_style = '';
	if ($et_type eq 'B' || $et_type eq 'C') {
		$tks_style = ' style="display:none;"';
		if ($Pay_version ne "1" && $bank_id ne "") {##ûѡ�е�
			$default_pay_bank=qq`
			function set_pay_bank(bank_id){
				var val_pay_by=document.operate.pay_by;
				if (val_pay_by.value=='') {
					for (var i = 0; i < val_pay_by.length; i++) {
						if (bank_id == val_pay_by.options[i].value) {
							val_pay_by.selectedIndex=i;
							break;
						}
					}
				}
				
		    }
			set_pay_bank("$bank_id");
			`;
		}
	}
	my $gpStyle=" style='display:none;'";
	my ($tagP,$tagG);
	if($et_type eq "G") { 
		$gpStyle=''; 
		if($Tag_str=~/(��|��)/){
			my $tag=$1;
			if($tag eq '��'){
				$tagG='selected';
			}
			elsif($tag eq '��'){
				$tagP='selected';
			}
		}
	}
	print qq`<tr><td colspan=13>
	<table width="100%" cellpadding="0" cellspacing="0" border="0">
		<tr align="left" height=25>
			<td style='width:90pt;'>Ʊ֤����:$tkt_type_list</td>
			<td id="gpTD"$gpStyle>������:<select name="pay_tag" id="pay_tag"><option value=''>--��ѡ��--</option><option value='��' $tagG>��-����</option><option value='��' $tagP>��-Ԥ�㵥λ</option></select></td>
			<td id="tks"$tks_style><span id="tks_string">��Դ:</span><select name="office_id" id="Tk_offices" style="width:100pt;" $lock_disd>$office_list</select></td>
			<td id="pay_box">֧��:<select name="pay_by" id='pay_bys' style="width:180px;" $getscript $lock_disd >$bank_list</select> 
			���:<input type="text" $p_read $Lock_sreadonly name="et_price" value="$ET_price" size="9" maxlength="9" style="width:50px;" onblur="numberformat(this);" /></td>
		</tr>
	</table>
	<input type="hidden" name="old_et_type" value="$et_type" />
	<input type="hidden" name="old_bank_id" value="$bank_id" />
	<input type="hidden" name="old_et_price" value="$ET_price" />
	<script type="text/javascript">
	$default_pay_bank
	var officelist = [$officelist];
	var kemulist = [$kemulist];
	function mod_tkt(type){
		document.getElementById('tks').style.display = '';
		if (type == 'Y') {// BSP
			document.getElementById('tks_string').innerHTML = 'Office�ţ�';
			changeOffice(officelist, 'ZW', '$office_id','');
			document.getElementById('pay_box').style.display = '';
		}
		else if (type == 'O' || type == 'G' || type == 'U' || type == 'T') {// BOP��GP��UATP
			document.getElementById('tks_string').innerHTML = 'Office�ţ�';
			changeOffice(officelist, 'Z', '$office_id','');
			document.getElementById('pay_box').style.display = '';
		}
		else if (type == 'W') {// �⹺
			document.getElementById('tks_string').innerHTML = '��Դ��';
			changeOffice(officelist, 'YP', '$office_id','');
			document.getElementById('pay_box').style.display = '';
		}else if (type=='B') {//B2B
			document.getElementById('tks_string').innerHTML = 'Office�ţ�';
			changeOffice(officelist, 'B', '$office_id','$old_b2b_user');
			document.getElementById('pay_box').style.display = '';
		}
		else {//B2C
			document.getElementById('tks_string').innerHTML = '��Դ��';
			changeOffice(officelist, '', '$Corp_office','');
			document.getElementById('tks').style.display = 'none';
			document.getElementById('pay_box').style.display = '';
		}
		if(type == 'G'){
			document.getElementById('gpTD').style.display = '';
		}
		else{
			document.getElementById('gpTD').style.display = 'none';
		}
		// ��Ŀ
		$kemuscript
	}
	var changeOffice = function(data, type, defaultid,default_b2b_user)
	{
		var listobj = document.getElementById('Tk_offices');
		removeAll(listobj);
		var defaultselected = '---- Ʊ֤��Դ ---';
		if (type == 'Z' || type == 'B') {
			defaultselected = '--- Office�� ---';
		}
		listobj[listobj.options.length] = new Option(defaultselected, '');
		var listnum = 1;
		var listcolor = {'P' : 'magenta', 'Y' : 'red', 'Z' : '' , 'B' : '','W' : 'red'};
		var no_default="Y";
		for (var cityid in data)
		{
			if (type != '' && type.indexOf(data[cityid][2]) < 0)
			{
				continue;
			}
			listobj[listobj.options.length] = new Option(data[cityid][0] + ' ' + data[cityid][1], data[cityid][0]);
			var typeid = data[cityid][2];
			if (typeid != '')
			{
				listobj.options[listnum].style.color = listcolor[typeid];
				listnum++
			}
			
			if (defaultid != '' ) {
				
				if (type=='B' && default_b2b_user !='' && data[cityid][0].indexOf(defaultid) >=0) {
					
					if (default_b2b_user==data[cityid][3]) {
						listobj.options.selectedIndex = listnum - 1;
					}
					no_default="";
					
				}else if (defaultid == data[cityid][0]){
					listobj.options.selectedIndex = listnum - 1;
					no_default="";
				}
			}
		}
		if (no_default=="Y" && defaultid != '') {//û�е�Ĭ�ϼӽ�ȥ   liangby/2013.09.03
			listobj[listobj.options.length] = new Option(defaultid,defaultid);
			listobj.options.selectedIndex = listobj.options.length - 1;
		}
		if (listobj.options.length == 2) {
			listobj.options.selectedIndex = 1;
		}
	}
	var changeKemu = function(data, type, defaultid)
	{
		var listobj = document.getElementById('pay_bys');
		removeAll(listobj);
		document.operate.Pay_kemu.value='$Pay_kemu';
		var defaultselected = '��ѡ��֧������';
		listobj[listobj.options.length] = new Option(defaultselected, '');
		var listnum = 1;
		for (var cityid in data)
		{
			if (type != '' && data[cityid][3].indexOf(type) == -1)
			{
				continue;
			}

			listobj[listobj.options.length] = new Option(data[cityid][2], data[cityid][1]);

			if ('$Corp_center' == data[cityid][0]) {
				listobj.options[listnum].style.color = '#0000FF';
			}
			if (defaultid != '' && defaultid == data[cityid][1]) {
				listobj.options.selectedIndex = listnum;
			}
			listnum++;
		}
	}
	// ��ʼ�������������ʱĬ��ֵ
	window.onload = function(){
		mod_tkt(document.getElementById('et_type').value);
	};
	</script>
	`;
	$tk_js = qq`
		var ettype = document.getElementById('et_type').value;
		if (ettype == '')
		{
			alert("�Բ�����ѡ��Ʊ֤���ͣ�");
			return false;
		}
		else if (ettype == 'Y')
		{
			if (document.getElementById('Tk_offices').value == '')
			{
				alert('�Բ�����ѡ��Office�ţ�');
				document.getElementById('Tk_offices').focus();
				return false;
			}
		}
		else if (ettype == 'B' || ettype == 'C' || ettype == 'O' || ettype == 'U')
		{
			if (document.operate.pay_by.value == '')
			{
				alert('�Բ�����ѡ��֧�����У�');
				return false;
			}
			if (document.operate.et_price.value == '')
			{
				alert('�Բ���������֧����');
				document.operate.et_price.focus();
				return false;
			}
			var in_total=Round(document.operate.in_total.value,$Dec_round_2);
			var et_price=Round(document.operate.et_price.value,$Dec_round_2);
			if (in_total != et_price) {
				var ret=confirm('֧�����ͬ�����ͬ���Ƿ�ǿ�м�����');
				if (ret==false) {
					document.operate.et_price.focus();
					return false;
				}
			}
		}
		else if (ettype == 'W')
		{
			if (document.getElementById('Tk_offices').value == '')
			{
				alert('�Բ�����ѡ��Ʊ֤��Դ��');
				document.getElementById('Tk_offices').focus();
				return false;
			}
			if (document.operate.pay_by.value == '')
			{
				alert('�Բ�����ѡ��֧�����У�');
				document.operate.pay_by.focus();
				return false;
			}
			if (document.operate.et_price.value == '')
			{
				alert('�Բ�����ѡ��֧����');
				document.operate.et_price.focus();
				return false;
			}
			var in_total=Round(document.operate.in_total.value,$Dec_round_2);
			var et_price=Round(document.operate.et_price.value,$Dec_round_2);
			if (in_total != et_price) {
				var ret=confirm('֧�����ͬ�����ͬ���Ƿ�ǿ�м�����');
				if (ret == false) {
					document.operate.et_price.focus();
					return false;
				}				
			}
		}`;
}
## ��ѯ��עģ��	fanzy@2013-11-18
my $cmt_list_type;
$sql = "select Page_ID,Page_name,Page_file from ctninfo..Corp_page where Corp_ID='$Corp_ID' and Page_type='B' order by Page_ID ";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row=$db->ct_fetch) {
			$cmt_list_type .= qq!<a href="javascript:cmt_add('$row[2]');" title="$row[2]"><font color=maroon>$row[1]</font></a>\n!;
		}
	}
}
print qq!</td></tr>
<tr><td colspan=13>
	<table border=0 width=100% cellpadding=0 cellspacing=0 bgcolor=fffff0>
	<tr><td valign=top>
	������ע��
	<div><a href="javascript:void(0);" id="cmtmd" onmouseover="javascript:showMenu(this.id, false, 1)"><font class="Cmttemplate">ѡ��ģ��</font></a><div id="cmtmd_menu" class="sub_menu_box" style="display:none;margin-left:18px;">$cmt_list_type</div></div>
	</td>
	<td>
	<textarea name='Comment' rows='3' _maxLength='200'  wrap='hard' style='font-size:9pt;width:520px;'>$Comment</textarea>	
	</td></tr>
	</table>
</td></tr>
</table>!;


## -------------------------------------------------------------
## �տ������¼
## -------------------------------------------------------------
my $is_ban;
print qq!<tr bgcolor=f0f0f0 id='B1' style='display:none;'><td>\n!;
my $km_info;
if ($Pay_version eq "1") {	## ��ʾƾ֤��¼
	if ($Tag_str=~/\!/) {
		##��ȡ��ƿ�Ŀ����Ϣ��ϣ��  liangby@2010-12-11
		%kemu_hash = &get_kemu($Corp_center,"","hash2","","","","","","","Y");
		## Ʊ֤��Դ
		%office_name=&get_office($Corp_office,"","hash2","A");
		## ��ȡ������˶����Ŀ�Ŀ��Ϣ
		my @cert =&query_airbook_kemu($in{Reservation_ID});
		## ������Ŀ����
		%assist_type=&get_dict($Corp_center,6,"","hash");
		## ������Ϣ	dabin@2011-4-2
		$sql = "select a.Insure_corp,b.Office_name,a.Insure_type,a.Out_price,rtrim(a.Insure_name),Is_inter
			from ctninfo..Corp_insure a,
				ctninfo..Corp_office b
			where a.Insure_corp *= b.Office_ID
				and a.Corp_ID='$Corp_center'
				and a.Corp_ID='$Corp_center' 
				and b.Office_type='B' 
				and a.Is_use='Y' \n";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$insure_corp{$row[2]}=$row[0];		
					$insure_corp_name{$row[2]}=$row[1];			
					$insure_out_price{$row[2]}=$row[3];
					$insure_name{$row[2]}=$row[4];
					$insure_inter{$row[2]}=$row[5];
				}
			}
		}
		$can_del_all="Y";
		## ��ʾ�˶�����ƾ֤��ϸ
		$km_info =&display_airbook_cert($in{Reservation_ID},@cert);
	}
}
my $a_detail = &show_air_pay($in{Reservation_ID},$tbook,"");	
if ($a_detail eq "") {
	print "<table border=0 width=100% cellpadding=0 cellspacing=1 bgcolor=white>
	<tr><td height=282 align=center valign=middle><font color=red><b>�˶�������������¼��</td></tr>";
}
else{
	print "<table border=0 width=100% cellpadding=0 cellspacing=1 bgcolor=white>
	$a_detail";
}
print qq!</table></td></tr>

<tr><td id='C1' style='display:none;'>
$km_info</td></tr>!;

print qq!</table>
<table border=0 cellpadding=0 cellspacing=0><tr><td height=3></td></tr></table>
<div align=right>
<input type=hidden name="T_num" id="T_num" value='$person_num'>
<input type=hidden name=Pay_kemu value='$Pay_kemu'>
<input type=hidden name=ticket_total value='$ticket_total'>
<input type=hidden name=Reservation_ID value='$in{Reservation_ID}'>
<input type=hidden name=Sign value='$in{Sign}'>
<input type=hidden name=User_ID value='$in{User_ID}'>
<input type=hidden name=Serial_no value='$in{Serial_no}'>
<input type=hidden name=Refresh value='$in{Refresh}'>
<input type=hidden name=old_tkt_time value="$old_tkt_time" />
!;

print qq`
<script type="text/javascript">
function button_onclick() {
	$tk_js
	$confirm_js
	document.operate.bt_ok.disabled = true;
}

// �����������
function numberformat(e)
{
	var val = /^[+|-]?\\d+\\.?\\d*\$/.test(e.value);
	if(!val && e.value != "") {
		alert("ֻ���������֣����飡");
		e.style.background = '#FCFFA2';
		e.focus();
		return false;
	}
	else {
		e.style.background = '#ffffff';
	}
}

function create_inprice() {
	try
	{
		var fid_list = document.getElementById('fid_list');
		document.getElementById('tk_fids').value = '$tk_in_price';
		for (var i = 0; i < 13;) {
			fid_list[fid_list.options.length] = new Option(i.toFixed(1), i.toFixed(1));
			if(i<10){
				i += 0.5;
			}
			else{
				i ++;
			}
		}
	}
	catch (error){}
}
create_inprice();
</script>`;

if ($in{Contrast_target} eq 'Y') {
	my $p_num=0;
	if (($Adult_num == 0 || $Child_num == 0) && $Baby_num == 0) {
		$p_num=$Adult_num+$Child_num;
	}
	my $file_report = '';
	my $tk_num=1;
	$sql = "SELECT Ticket_number,Agent_price, Agent_tax FROM ctninfo..Contrast_Data 
		WHERE ID=$in{Contrast_ID} AND Reservation_ID='$in{Reservation_ID}' AND Ticket_status='N' AND Data_source='F' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row=$db->ct_fetch) {
				$Agent_price+=$row[1];
				my $tkid=substr($row[0],3,10);
				if (length($row[0]) > 13) {					
					my $l_num=substr($tkid,0,7).substr($row[0],14,3);
					$tk_num=$l_num-$tkid+1;
				}
				if ($p_num > 0) {	$row[1] = $row[1]/$p_num;	}
				for (my $i=0;$i<$tk_num;$i++) {
					$file_report .= qq`\n\t'$tkid' : {'price' : '$row[1]', 'discount' : '$row[2]'},`;
					$tkid++;
				}
			}
		}
	}
	if ($file_report ne '') {	chop($file_report);	}
	$profit =~ s/\s*\.00//;
	my $a_msg;
	if ($profit == $Agent_price) {
		#$in{Contrast_target}="";
	}
	else{
		$a_msg=qq!return showPopDialog('Confirm', '�޸Ĵ������', '�����ڵĴ����Ϊ $profit �������ڵĴ����Ϊ $Agent_price ���Ƿ�����µĴ���ѣ�<br/>ȷ�������밴�����ܡ��������밴��ȡ������');!;
	}
	
	## �Ƚ������Ƿ���ͬ
	print qq`
	<script type="text/javascript">
	function showPopDialog(showType, showTitle, showContent) {
		mask = new Mask();
		popups = new Popups("append_parent");
		popups.createPopup(showType, showTitle, showContent, '�� ��', CallBack).show();
	}
	// �ص�����
	function CallBack(s) {
		changePrice();
		return true;
	}

	function checkPrice() {
		$a_msg
	}

	function changePrice() {
		var file_report = {$file_report};
		var T_num = document.getElementById('T_num').value;
		for (var i = 0; i < T_num; i++) {
			var discountid = document.getElementById('in_dis_' + i);
			var priceid = document.getElementById('Agent_price_' + i);
			var tid = discountid.getAttribute('tid');
			if (typeof(file_report[tid]) != 'undefined') {
				discountid.value = file_report[tid]['discount'];
				priceid.value = file_report[tid]['price'];
				cal_tk_comm(i, priceid);
			}
		}
	}
	checkPrice();
	</script>
	`;
}
$Lock_book_btn=$lock_tips;
if (&Binary_switch($Function_ACL{HSKJ},1,'A')==1) {
	my $Lock_book_st=($Tag_str=~/��/)?"checked":"";
	$Lock_book_btn=qq`
	<label title="�������ݱ������󣬾��޸Ķ��������޸Ķ�������Ʊ�޸�ҳ�� ����ƺ��㡢��Ӷ���㡢ȡ���������쳣����û�С����������������ݲ������޸������ѱ������Ķ��������˺Ŷ��������޸Ķ����Ľ�cid����Ʊ����">
		<input type="checkbox" name="Lock_book" value='Y' $Lock_book_st/>
		<img src="/admin/index/images/lock.gif" align=absmiddle >������������
	</label>`;
}
if ($Tag_str=~/\!/) {
	my @tmp_array_list = ();
	my $t_assist;
	print "<div align=left>";
	## ��ȡ������Ŀ
	my @assist=&get_kemu($Corp_center,"","array","","","","assist","N","","Y");
	my (@i_kemu,@i_assist);
	for (my $i=scalar(@assist);$i>=0;$i--) {
		if (index($assist[$i]{Type_ID},':')>=0) {
			unshift(@i_assist,{	
				ID=>$assist[$i]{Type_ID},
				Name=>$assist[$i]{Type_name},
				Pid=>$assist[$i]{Pid}
			});
		}
		else{
			if ($t_assist eq "") {	$t_assist = $assist[$i]{Type_ID};}
			my $is_parent;
			if ($t_assist ne $assist[$i]{Type_ID}) {
				if (index($t_assist,$assist[$i]{Type_ID})==0) {
					$is_parent="Y";
					#print "<font color=blue>$assist[$i]{Type_ID} $assist[$i]{Pid} $assist[$i]{Type_name}</font><br>";
				}
				else{
					$t_assist = $assist[$i]{Type_ID};
				}
			}
			if ($is_parent eq "" && $t_assist ne "") {
				my $t_id=$assist[$i]{Type_ID};
				my $km_name=$kemu_hash{$t_id}[0];
				my $i_pos=rindex($t_id,'.');
				if ($i_pos > 0) {	$t_id=substr($t_id,0,$i_pos);		}
				for (my $j=0;$j<5;$j++) {						
					$km_name = "$kemu_hash{$t_id}[0]_$km_name";
					my $i_pos=rindex($t_id,'.');
					if ($i_pos > 0) {	$t_id=substr($t_id,0,$i_pos);		}
					else{	$j=5;	}
				}
				#print "$assist[$i]{Type_ID} $assist[$i]{Pid} $assist[$i]{Type_name} $assist[$i]{Parent} <font color=red>$km_name</font><br>";
				unshift(@i_kemu,{	
					ID=>$assist[$i]{Type_ID},
					Name=>$km_name,
					Pid=>$assist[$i]{Pid}
				})
			}				
		}			
	}

	## �����Ŀ�б�
	my $ass_ids;
	for (my $i = 0; $i < scalar(@i_kemu); $i++) {
		if ($i_kemu[$i]{ID} eq $i_kemu[$i]{Pid}) {		$i_kemu[$i]{Pid} = '';	}
		my $listitem = qq`['$i_kemu[$i]{Corp_ID}', '$i_kemu[$i]{ID}', '$i_kemu[$i]{Name}', '$i_kemu[$i]{Pid}','0']`;
		push(@tmp_array_list, $listitem);
		if ($i_kemu[$i]{Pid} ne "") {
			$ass_ids .= "','$i_kemu[$i]{Pid}";
		}
	}
	## ���������б�
	if ($ass_ids ne "" && $Pay_version == 1) {
		for (my $i = 0; $i < scalar(@i_assist); $i++) {
			my $listitem = qq`['$i_assist[$i]{Corp_ID}', '$i_assist[$i]{ID}', '$i_assist[$i]{Name}', '$i_assist[$i]{Pid}','1']`;
			push(@tmp_array_list, $listitem);
			$bank_name{$i_assist[$i]{ID}}=$i_assist[$i]{Name};
		}
	}

	## ����
	my $s_assist_type;
	foreach my $tkk (sort keys %assist_type) {
		if ($tkk == 2 || $tkk == 3 || $tkk == 4 || $tkk == 8) {
			my $t_ck;	if ($tkk == 3) {	$t_ck=" checked";		}
			#$s_assist_type .= qq!<input type=radio name=i_type $t_ck value='$tkk' onclick="hd('hs')">$assist_type{$tkk}\n!;
			$s_assist_type .= qq!<input type=radio name=i_type $t_ck value='$tkk'>$assist_type{$tkk}\n!;
		}			
	}
	## ����
	my $s_dept;
	foreach my $tkk (sort keys %dept) {
		$s_dept .= "<option value='$tkk'>$dept{$tkk}</option>\n";
	}

	my $list1_oh_str = '';
	if ($Pay_version eq "1") {
		$list1_oh_str=qq! onchange="changelist('i_kemu', 'i_assist')"!;
	}
	if ($et_type eq "B"){	$i_office="$air_code";	}	else{	$i_office="$office_id";		}	
	my $ins_corp=$insure_corp{$Insure_type};
	if ($ins_corp eq "") {	$ins_corp=$Corp_center;	}
	my $op='P';
	if ($i_office eq "") {	$op='W';	}
	if ($can_del_all eq "Y") {
		print qq!<script>
			function del_cert_all(){
				var ret=confirm("��ȷ��Ҫɾ���˶�����ȫ��ƾ֤��¼��");
				if (ret) {					
					document.operate.Op.value='delall';
					document.operate.submit();
				}
			}
			</script>!;
		$can_del_all = qq!<input type="button" value='ɾ������ƾ֤' class="btn20" style='color:red;' onclick="del_cert_all();" />!;
	}
	else{
		$can_del_all = qq!<input type="button" value='ɾ������ƾ֤' class="btn20" style='color:red;' onclick="alert('����ɾ��ƾ֤���ܷ�¼��Ϣ��');" />!;
	}
	print qq!</table>
	<table border=0 width=100% cellpadding=1 cellspacing=1 bgcolor=white  height=100% id="box_assist_head" style="display:none;">
	<tr><td height=20 valign=bottom>			
		<table border=0 width=100% cellpadding=0 cellspacing=0 bgcolor=white>
		<tr>
			<td><font color=red>�ֹ���������ƾ֤��¼��</font></td>
			<td align=right><span align=right>ƾ֤���ڣ�<select name=Cert_date >$op_date_list</select></span></td>
		</tr>
		</table>
	</td></tr>
	<tr bgcolor=f0f0f0><td>			
		<table border=0 width=100% cellpadding=0 cellspacing=0 bgcolor=fffff0>
		<tr>
		<td>���˶���$s_assist_type </td>
		<td align=right>�ơ���Ŀ��<select name="i_kemu" id="i_kemu" style="width:200pt;"$list1_oh_str></select></td>
		</tr>
		<tr><td>�������<input type=radio name='i_debt' value='0'>��[0]
			<input type=radio name='i_debt' value='1' checked>��[1]
			������<input type=text name='i_amount' value='$i_amount' class=input_num size=10>
		</td>
		<td id="hs" align="right" style="display:none;">������Ŀ��<select name='i_assist' id="i_assist" style='width:200pt;'>$s_assist_list</select></td>
		</tr>
		</table>
	</td></tr>
	<tr><td>
		<div align=right>$Lock_book_btn
	<input type=hidden name=Op value='$op'>
	<input type=hidden name=i_corp value='$corp_id'>
	<input type=hidden name=i_office value='$i_office'>
	<input type=hidden name=i_dept value='$corp_info{$corp_id}[1]'>
	<input type=hidden name=i_insure value='$ins_corp.$Insure_type'>
	<input type=hidden name=Show value='$in{Show}'>
	<input type=hidden name=Serial_ID value=''>	
	<input type="submit" value='ȷ��' class="btn21" name="bt_ok" />
	<input type="reset" value='����' class="btn21" />
	$can_del_all</form>
	</div>
	</td></tr>
	</table>
	
	
	!;		
	if ($in{Show} eq "P") {
		if ($i_office eq "") {
			print "<script>
				alert('�������ö�����Ʊ֤���ͺ�Office��Ϣ��')
				Show('A','A1','W');
			</script>";
		}
		else{
			print "<script>Show('C','C1','P');</script>";
		}
	}

	## ������Ŀ����
	my $array_list = join(",\n", @tmp_array_list);
	print qq`
	<script type="text/javascript">
	var datalist = [$array_list];

	function createlist(list, pid) {
		removeAll(list);
		if (list.id=='i_assist') {
			list.style.display ='';
			document.getElementById("hs").style.display='';
		}
		var listnum = 0;
		var bank_gid = '';
		var exists_value = [];
		for (var i = 0; i < datalist.length; i++) {
			if (pid != '' && datalist[i][1] == pid) {
				bank_gid=datalist[i][1];
			}
			if (pid != '' && (datalist[i][4] != '1' || bank_gid != datalist[i][3])){
				continue;
			}
			if (pid == '' && datalist[i][4] != '0')	{	// ���ʽ
				continue;
			}
			if (array_exists(exists_value, datalist[i][1]))	// �����ظ��������б�
			{
				continue;
			}
			list[list.options.length] = new Option(datalist[i][2], datalist[i][1]);
			exists_value.push(datalist[i][1]);	// д����������������ж��ظ�
			if (datalist[i][3] \!= '') {
				list.options[listnum].style.color = 'blue';
			}
			listnum++;
		}
		if (listnum>0) {
			list.options.selectedIndex=0;
		}
		else{
			if (list.id=='i_assist') {
				list.style.display ='none';
				document.getElementById("hs").style.display='none';
			}
		}
	}
	function changelist(src, obj) {
		src = document.getElementById(src);
		obj = document.getElementById(obj);
		var srcvalue = '';
		if (src)
		{
			srcvalue = src.options[src.options.selectedIndex].value;
		}
		createlist(obj, srcvalue);
	}
	changelist('', 'i_kemu');
	</script>
	`;
	exit;
}
if ($Tag_str=~/\!/) {
	print "</table><font color=red><br>��ʾ�������Ѿ����ɻ��ƾ֤�������ٽ��С���ƺ��㡿������</font>";
	exit;
}

print qq!$Lock_book_btn<input type=hidden name=Op value='W'>
<input type=hidden name="Contrast_target" value='$in{Contrast_target}' />
<input type=hidden name="Contrast_ID" id="Contrast_ID" value='$in{Contrast_ID}' />
<input type="submit" value='ȷ��' class="btn20" name="bt_ok" />
<input type="reset" value='����' class="btn20" /></form>
!;

