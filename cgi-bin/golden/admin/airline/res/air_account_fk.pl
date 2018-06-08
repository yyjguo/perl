#!c:/Perl/bin/Perl.exe
require "ctnlib/golden/common.pl";
require "ctnlib/golden/html.pl";
require "ctnlib/golden/datelib.pl";
require "ctnlib/golden/air_account.pl";
require "ctnlib/golden/manage.pl";
require "ctnlib/golden/air_res.pl";
require "ctnlib/golden/cgi-lib.pl";
require "ctnlib/golden/SMSPost.pl";
require "ctnlib/golden/smstools.pl";
require "ctnlib/golden/my_sybperl.pl";
require "ctnlib/golden/air_pay.pl";
require "ctnlib/golden/inc_lib.pl";

use Sybase::CTlib;
use CGI::Apache qw(:standard :cgi-lib);
use URI::Escape;
## =====================================================================
## start program
## ---------------------------------------------------------------------
#&ReadParse();  
&CGI::ReadParse(*in);
## ---------------------------------------
if ($in{data_type} eq "json") {
	print "Pragma:no-cache\r\n";
	print "Cache-Control:no-cache\r\n";
	print "Expires:0\r\n";
	print "Content-type:text/html;charset=GBK\n\n";
}else{
	&Header("���񸶿�-�������Ӧ��");
}
## ---------------------------------------
foreach my $tt (keys %in) {##����sqlע��   liangby@2014-8-12
	$in{$tt}=&param_filter($in{$tt});
}
$Corp_ID = ctn_auth("CWSY");
if(length($Corp_ID) == 1) { exit; }
## =====================================================================
## ���ڴ���
$today = &cctime(time);
($week,$month,$day,$time,$year)=split(" ",$today);
if($day<10){$day="0".$day;}
$today=$year.".".$month."."."$day";
if ($in{data_type} eq "json") {##��ȡ�հ׵���Ӧ�̺͹�Ӧ���տ��˻���Ϣ  ���հ׵����ӱ�ע�޸ģ�linjw@2016-11-18��
	$policyList="";

	$sql=" select rtrim(b.Birthday),b.Print_no,b.Card_ID,b.Cust_name,b.Ds_amount-Isnull(b.Ds_recv,0),a.User_rmk 
		from ctninfo..Inc_book a,ctninfo..Inc_book_detail b
		where a.Res_ID=b.Res_ID 
		and b.Res_ID='$in{Res_ID}' \n";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				if ($row[0] ne "" && $row[4] !=0) {
				
					if ($policyList ne "") {
						$policyList .=",";
					}
					$refuse_remark=$row[5];
					$policyList .="{'sp_corp':'$row[0]','account_info':'��Ӧ���տ��˻���Ϣ:�����У�$row[1]  ��������$row[2]  �˺ţ�$row[3]','sp_amount':'$row[4]'}";
				}
			}
		}
	}
	if ($policyList eq "") {
		$policyList ="[]";
	}else{
		$policyList ="[".$policyList."]";
	}
	$status="OK";
	$message="";
	$result = qq`$in{callback}({'message':"$message",'status':"$status",'sp_corpinfo':$policyList,'refuse_remark':'$refuse_remark' });`;

	$result =~ s/\r\n/\<br \/>/g;
	print $result;
	exit;
}

#�ϴ��ļ�IP��ת fanzy@2016.10.13
&skip_serverip_form();
if ($in{Depart_date} ne "") {	$Depart_date=$in{Depart_date};	}	else {	$Depart_date = $today;	}

if ($Depart_date ne ""){
	$nextdate=&Nextdate($Depart_date);
	$prevdate=&Prevdate($Depart_date);
}
if ($in{End_date} eq "") {	$in{End_date} = $nextdate;	}
$End_date = $in{End_date};
## end of date 
if ($in{Start} eq "") {	$in{Start} = 1;	}
if ($in{Op} == -1) {	$in{Op} = 0;	}	
if ($in{Op} eq "") {	$in{Op} = -1;	}	
&get_op_type();
$in{Agent_ID_group}=~s/\ //g;
print qq!
<link rel="stylesheet" type="text/css" href="/admin/style/style.css" />
<link rel="stylesheet" type="text/css" href="/admin/style/tablelist.css" />
<link rel="stylesheet" type="text/css" href="/admin/style/style.css?v=20150204" />
<script type="text/javascript" src="/admin/js/popwin.js?ver=20110601"></script>
<script type="text/javascript" src="/admin/js/global.js?ver=20110601"></script>
<div id="append_parent"></div>
<style>
input{
	border: #B5B5B5 solid 1px;
}
</style>
<SCRIPT language="JavaScript" src="/admin/js/date/js/date1.js"></SCRIPT>
<IFRAME name=CalFrame id=CalFrame style="DISPLAY: none; Z-INDEX: 100; WIDTH: 148px; POSITION: absolute; HEIGHT: 194px" marginWidth=0 marginHeight=0 src="/admin/js/date/calendar.htm" frameBorder=0 noResize scrolling=no></IFRAME>!;
print qq`<script type="text/javascript" src="/admin/js/ajax/jquery-1.9.1.min.js"></script>
	<script type="text/javascript" src="/admin/js/multiselectSrc/jquery.ui.core.js"></script>
	<script type="text/javascript" src="/admin/js/multiselectSrc/jquery.ui.widget.js"></script>
	<script type="text/javascript" src="/admin/js/multiselectSrc/jquery.multiselect.js"></script>
	<link rel="stylesheet" type="text/css" href="/admin/style/multiSelect.css" />
	<script type="text/javascript">
		\$(function(){
			//\$("#Agent_ID").multiselect IE��Chrome���׳����Ǻ����Ĵ��� jf on 2018/5/16
			if(typeof \$("#Agent_ID").multiselect == "function"){
				try{
					\$("#Agent_ID").multiselect({
						noneSelectedText: "==��ѡ��==",
						checkAllText: "ȫѡ",
						uncheckAllText: '��ȫѡ',
						selectedList:2
					});
				}catch(e){
					console.log(e);
				}
			}
		});
	</script>`;
## =====================================================================
if ($in{down_data} eq "Y") {
	$dw_hidden = "none";
}else{
	$dw_hidden = "block";
}
if ($in{act} == 1) { ## �������� add by zhengfang 2007-11-9
	print qq!<form action='' method=post name=query id="query">!;
}else{ print qq!<form action='' method=get name=query id="query" style="display:$dw_hidden">!; }


if ($in{Order_type} eq "") {	$in{Order_type}=1;	}
if ($in{Order_type} eq "1") {	$a_bg=" class='current'";	}
elsif ($in{Order_type} eq "2") {	$o_bg=" class='current'";	}
elsif ($in{Order_type} eq "3") {	$a_bg=" class='current'";	}
elsif ($in{Order_type} eq "4") {	$c_bg=" class='current'";	}
elsif ($in{Order_type} eq "5") {	$d_bg=" class='current'";	}
else{	$i_bg = " class='current'";	}

my $href="air_account_fk.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}";
print qq!<div class="wrapper" id="setting_customer">
	<div class="tabNav" id="parameter_tabs">
		<ul>
		    <li$a_bg><a href="$href&Order_type=1"><img src="/admin/index/images/plane1.gif" />��Ʊ����</a></li>		
			<li$o_bg><a href="$href&Order_type=2"><img src="/admin/index/images/person.gif" />������Ʒ</a></li>			
		</ul>
	</div>
</div>\n!;


if ($in{Order_type} ==2) {
	$f_color1="blue";
	$f_color2="red";
	@op_name = ('������','�Ѹ�������','�����');
}elsif ($in{Order_type} ==1) {
	$f_color1="blue";
	$f_color2="red";
	@op_name = ('������','�Ѹ�������','�����');
}

print qq!<div class="tabNav" id="parameter_tabs2" style='height:20px;'>
<font style='font-size:11pt;'>���ࣺ!;
my $navBarHtml=""; ## �������ṹ
my $href=qq`air_account_fk.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Order_type=$in{Order_type}&Corp_ID=$in{Corp_ID}&user_book=$in{user_book}&Start=1&air_type=$in{air_type}&Depart_date=$Depart_date&End_date=$End_date&Sender=$in{Sender}&History=$in{History}&pay_obj=$in{pay_obj}&Send_corp=$in{Send_corp}&hfcw=$in{hfcw}&Op=`; ## ��ȡURL����ͬquerystring
for (my $i=0;$i<scalar(@op_name);$i++) {
	if ($in{Order_type} ==5 && $i==4) {
		$herf="javascript:inc_book('28');";
	}
	$navBarHtml.=qq!<a href="$href$i">!;
	if ($in{Op} == $i) {
		$navBarHtml.= "<font color=red>$op_name[$i]</a></font>|";
	}
	else{
		$navBarHtml.= "<font color=blue>$op_name[$i]</a></font>|";
	}
}

if ($in{Order_type} ==1 || $in{Order_type} ==2) {
	my $navBarHtml_extra="";  
	$sql=" select Logo_path from ctninfo..Corp_agent where Corp_ID='$Corp_ID' and Agent_type='9' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT) {
			while(@row = $db->ct_fetch) {
				$logo_path=$row[0];		## ����ǰ������̲���Ȩ��  jf @2018/5/18
			}
		}
	}
	if($logo_path =~ /f/){ ## ����"���񸶿�����'ҵ�������'����"
		my $op=3;
		$navBarHtml_extra .=qq!<a href="$href$op">!;
		if ($in{Op} == 3) {
			$navBarHtml_extra.= "<font color=red>ҵ�������</a></font>|";
		}
		else{
			$navBarHtml_extra.= "<font color=blue>ҵ�������</a></font>|";
		}
	}
	if($logo_path =~ /g/){ ## ���� "���񸶿����Ӳ������(����ǰ)����"
		my $op=4;
		$navBarHtml_extra .=qq!<a href="$href$op">!;
		if ($in{Op} == 4) {
			$navBarHtml_extra.= "<font color=red>�������</a></font>|";
		}
		else{
			$navBarHtml_extra.= "<font color=blue>�������</a></font>|";
		}
	}
	$navBarHtml = $navBarHtml_extra.$navBarHtml;
}

if ($in{date_type} eq "T") {	$t_ck=" selected";	}	
elsif ($in{date_type} eq "A") {	$a_ck=" selected";	}	
elsif ($in{date_type} eq "C") {	$c_ck=" selected";	}	
elsif ($in{date_type} eq "B") {	$b_ck=" selected";	}	
else{	$t_ck=" selected";	$in{date_type}="T";	}
if ($in{re_other} eq "Y") {
	$re_other_ck="checked";
}

print qq!$navBarHtml</font>
</div>

<table border=0 cellpadding=0 cellspacing=0 width=100%>!;
if ($in{Order_type} ==1) {
	if ($in{et_type} eq "") {
		$in{et_type}="W";
	}
	## Ʊ֤����
	my @tkt_type=&get_dict($Corp_center,3,"");
	my $tkt_type_list;
	my $tkt_type_sele;
    my $t_sel_all;
	for (my $i=0;$i<scalar(@tkt_type);$i++) {
		my $t_sel;
		if($in{et_type} eq "ALL"){
			$t_sel_all="selected=\"selected\"";
		}
		if ($in{et_type} eq $tkt_type[$i]{Type_ID}) {
			$t_sel = "selected=\"selected\"";
			$tkt_type_sele="$tkt_type[$i]{Type_name}";
		}
		$tkt_type_list.="<option value='$tkt_type[$i]{Type_ID}' $t_sel>$tkt_type[$i]{Type_name}</option>\n";
		$tkt_type_name{$tkt_type[$i]{Type_ID}}=$tkt_type[$i]{Type_name};
	}
	
	$tkt_type_list.="<option value=\"ALL\" $t_sel_all>ȫ��</option>";
	## Ʊ֤��Դ
	my $office_list="<option value=''>---- Ʊ֤��Դ ---</option>";
	my @office_array = &get_office($Corp_office,"","array","A","","Y");


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
	
	## ===========================================================================
	## ��ѯ��Ʊ����
	my $AGT_gp_ALL=($in{Agent_ID_group} eq "" || $in{Agent_ID_group} eq "ALL") ? "selected" : "";

	my $agt_group_list="<option value='ALL' $AGT_gp_ALL> ȫ �� </option>"; 
	my $where_age=&select_corp('T',"","","","","","","where","","","","","$in{c_limit}","","","Y");
	if ($where_age ne "") {
		$sql_agt="select rtrim(Corp_ID),Corp_csname from ctninfo..Corp_info $where_age order by Corp_type desc,Is_delivery desc,Corp_ID \n";
		if ($print_sql eq "Y") {
			print "<pre>13:$sql_agt</pre>";
		}
		@Agent_ID_group=split/,/,$in{Agent_ID_group};
		$db->ct_execute($sql_agt);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
					my $st;
					if ($in{Agent_ID_group} eq $row[0]) {
						$st=" selected ";
					}else {
						if (scalar(@Agent_ID_group)>1) {
							my $t_tag="N";
							foreach my $tt (@Agent_ID_group) {
								if ($tt eq $row[0]) {
									$t_tag="Y";
								}
							}
							if ($t_tag eq "Y") {
								$st=" selected ";
								
							}
							
						}
					}
					$agt_group_list.="<option value='$row[0]' $st>$row[1]</option>";
					$Corp_csname{$row[0]}=$row[1];
				}
			}
		}
	}
	##===========================================================================

	$officelist = join(',', @tmp_office_array);
	if ($in{air_type} eq "") {
		$in{air_type}="N";
	}
	$ck_air_typeall="";
	$ck_air_typey="";
	$ck_air_typen="checked";
	if ($in{air_type} eq "Y") {
		$ck_air_typeall="";
		$ck_air_typey="checked";
		$ck_air_typen="";
	}
	if ($in{air_type} eq "ALL") {
		$ck_air_typeall="checked";
		$ck_air_typey="";
		$ck_air_typen="";
	}
	my @ck_status=("checked","checked","checked","checked","checked","checked","checked","checked"); 
	for (my $i=0;$i<8;$i++){
		my $tk_status="tk_status_".$i;
		if($in{$tk_status} eq $i){
			$ck_status[$i]=" checked";
		}else{
			$ck_status[$i]=" ";
		}
	}
	print qq!<tr><td>���ͣ�<label for="air_type_all" ><input type=radio name=air_type id="air_ty[this.optiope_all" value="ALL" $ck_air_typeall/>ȫ��</label><input type=radio name=air_type id="air_type_n" value="N" $ck_air_typen/>����</label><label for="air_type_y"><input type=radio name=air_type value="Y" id="air_type_y" $ck_air_typey >����</label>
		  Ʊ֤���ͣ�<select name="et_type" id="et_type" onchange="mod_tkt(this.options[this.options.selectedIndex].value)" style="width:50px;">$tkt_type_list</select> <span id="tks_string">��Դ:</span><select name="office_id" id="Tk_offices" style="width:100pt;">$office_list</select>!;
	if ($in{Op} eq 1){
		print qq! ���ʽ:<select name="pay_by1" id='pay_bys1' style="width:180px;" ></select> !;
	}
	print qq!<br>
		  Ʊ֤״̬:
		<label><input id="all_status" type="checkbox" onclick="selectAll();"/>ȫ��</label>
		<label><input id="tk_status_0" name="tk_status_0" type="checkbox" value="0"  $ck_status[0]/>����</label>
		<label><input id="tk_status_1" name="tk_status_1" type="checkbox" value="1"  $ck_status[1]/>��Ʊ</label>
		<label><input id="tk_status_2" name="tk_status_2" type="checkbox" value="2"  $ck_status[2]/>����</label>
		<label><input id="tk_status_3" name="tk_status_3" type="checkbox" value="3"  $ck_status[3]/>����</label>
		<label><input id="tk_status_4" name="tk_status_4" type="checkbox" value="4"  $ck_status[4]/>����</label>
		<label><input id="tk_status_5" name="tk_status_5" type="checkbox" value="5"  $ck_status[5]/>׷λ</label>
		<label><input id="tk_status_6" name="tk_status_6" type="checkbox" value="6"  $ck_status[6]/>ADM</label>
		<label><input id="tk_status_7" name="tk_status_7" type="checkbox" value="7"  $ck_status[7]/>ACM</label>	
		<span onblur="showValues()">��Ʊ������<select  style="width:55px;"  id='Agent_ID' multiple="multiple" size="6">$agt_group_list</select></span>
	</td>
	</tr>!;
}
print qq!<tr><td height=28>!;
if ($User_spacl =~ /A/ && $Corp_center eq "WUH294") {
## ���Ʋ���ʾ�ͻ�����
}
elsif($in{Order_type} != 1){
	print qq`�ͻ���`;
	&select_corp("","$in{Corp_ID}"," style='width:60pt;'","Corp_ID","<option value=''>------ ��ѡ��ͻ� ------");
}
if ($User_spacl=~/A/ && $User_type ne "S" && $Corp_center eq "WNZ101") {
	$in{user_book}=$in{User_ID};
	print qq!<input type=hidden name=user_book value='$in{user_book}'>!;
}else{
	print qq!����Ա��<input type="text" name="user_book" id="user_book" size=10 value="$in{user_book}" cust_pin="right" cust_title="����Ա����"  cust_changes="ALL" custSug="0" ajax_url="/cgishell/golden/admin/manage/get_ffp.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Form_type=user&type=A">��!;
}
if ($in{Order_type} == 1) {
	print qq!Ʊ���ţ�<input type=text name=tkt_id value='$in{tkt_id}' style='width:140px;' title='������10λƱ��(��,�ŷָ��������)��ֻ�ṩ���뿪ʼ����һ�������ڵ�Ʊ�Ų�ѯ'>  !;
}
$dw_link .= $in{$_} ne "" && $_ ne "down_data" ? "&$_=$in{$_}" : "" for %in;
$dw_link =~ s/&/\?/;
#print "<pre>$dw_link";
$dw_button=" <input type=button value='��������' class=btn30 onclick='dw_data();'> ";

print qq` �����ţ�<input type=text name=Res_ID style='width:76pt;' value="$in{Res_ID}" size=16 /> `;
my $date_list = qq~
<option value='T'$t_ck>��Ʊ����</option>
<option value='B'$b_ck>��������</option>
<option value='A'$a_ck>��������</option>
<option value='C'$c_ck>�������</option>
~;
if($in{nopaging} eq "Y"){
	$page_ck=" checked";
}else{
	$page_ck=" ";
}
print qq!
<select name=date_type>
$date_list
</select>
<font style='font-size:11pt;'>
<a href="javascript:upDepart_date('$prevdate');" title='��ǰһ��'><font face=webdings>7</font></a>
<input type=text name=Depart_date id=sdate size=10 maxlength=10 style='border: #B5B5B5 solid 1px;' value='$Depart_date' onclick="event.cancelBubble=true;ShowCalendar(document.getElementById('sdate'),document.getElementById('sdate'),null,0,330)">!;
print qq!-<input type=text name=End_date id=edate size=10 maxlength=10 style='border: #B5B5B5 solid 1px;' value='$in{End_date}' onclick="event.cancelBubble=true;ShowCalendar(document.getElementById('edate'),document.getElementById('edate'),null,0,330)">
<a href="javascript:upDepart_date('$nextdate');" title='����һ��'><font face=webdings>8</font></a>!;
if ($in{Order_type} == 1){
	print qq!
<label for="nopaging" style="font-size:9pt;"><input name="nopaging" type="checkbox" value="Y" id="nopaging" $page_ck/>��ʹ�÷�ҳ</label> !;
}

print qq!
<input type=submit class=btn30 value=' ��ѯ '> $dw_button<img src='/admin/index/images/print.gif' align=absmiddle>!;
if($in{Order_type} == 1 || $in{Order_type} == 2){
	print qq!<a href="javascript:goPrint()">��ӡ��ҳ����</a>!;
}
print qq!</td>
<input type=hidden name=Op value='$in{Op}'>
<input type=hidden name=Order_type value='$in{Order_type}'>
<input type=hidden name=User_ID value='$in{User_ID}'>
<input type=hidden name=Serial_no value='$in{Serial_no}'>
<input type=hidden name=Select_the id=Select_the value='$in{Select_the}'>
<input type=hidden name=Agent_ID_group id="Agent_ID_value" value="$in{Agent_ID_group}"></td>
</tr>
<tr><td height=1 bgcolor=808080 colspan=2></td></tr>
</table>
<script type="text/javascript">
// ��ȡDOMԪ��,�ɴ���DOM�������id�ַ�������Ҫ��д���ش˺��� jf on 2018/5/23 
function Fid(id){  
    return typeof(id) === "string"?document.getElementById(id):id;    
}  
function dw_data(){
	window.open(\'air_account_fk.pl$dw_link&down_data=Y\','_blank','width=650,height=150,menubar=no,toolbar=no, status=no,scrollbars=yes');
}
function upDepart_date(Depart_date){
	Fid('sdate').value=Depart_date;
	Fid('edate').value="";
	Fid('query').submit();
}
function inc_book(pro_id){
	var window_name="Ԥ��������Ʒ��";
	if (pro_id=='10') {
		window_name="�����տ";
	}else if(pro_id=='27'){
		window_name="�������";
	}else if (pro_id=='28') {
		window_name="������";
	}
	//pmwin('open', '/cgishell/golden/admin/inc_goods/inc_book_form.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Pro_id='+pro_id, window_name,700,480);
	OpenWindow('/cgishell/golden/admin/inc_goods/inc_book_form.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Pro_id='+pro_id, window_name,'resizable,scrollbars,width=700,height=480');
}
function OpenWindow(theURL,winName,features) { 
  window.open(theURL,winName,features);
}
function showValues() {
	var valuestr = \$("#Agent_ID").multiselect("MyValues");
	var valu = Fid("Agent_ID_value").value=valuestr;	
}
function selectAll(){
	for(var i=0;i<8;i++){
		if(Fid("tk_status_"+i) && Fid("all_status")){
			Fid("tk_status_"+i).checked=Fid("all_status").checked;
		}
	}
}
/* IIFE TO CHECK ALL  modified by jf on 2018-5-23 */
;(function(){ 
	for(var i=0;i<8;i++){
		if(Fid("tk_status_"+i) && Fid("all_status")){
			Fid("tk_status_"+i).onclick=function(){
				var recordNumber=0;
				for(var j=0;j<8;j++){
					if(Fid("tk_status_"+j).checked){
					}else{
						recordNumber++;
					}
				}
				if(recordNumber == 0){
					Fid("all_status").checked=true;
				}else{
					Fid("all_status").checked=false;
				}
			}
		}
	}	
})();
function goPrint(){
	window.open('/print.htm','win')
}
</script>
!;
if ($in{Order_type}==1) {
	print qq`<script>
	var officelist = [$officelist];
	var removeAll = function(obj)
	{
		obj.options.length=0;
	}
	function mod_tkt(type){
		
		if (type == 'Y') {// BSP
			Fid('tks_string').innerHTML = 'Office�ţ�';
			changeOffice(officelist, 'Z,W', '$in{office_id}','');
			if ($in{Op} == 1){
				changeKemu1('a');
			}
		}
		else if (type == 'O' || type == 'G' || type == 'U') {// BOP��GP��UATP
			Fid('tks_string').innerHTML = 'Office�ţ�';
			changeOffice(officelist, 'Z,W', '$in{office_id}','');
			if ($in{Op} == 1){
				if (type == 'O'){
					changeKemu1('4');
				}else if(type == 'G'){
					changeKemu1('5');
				}else if(type == 'U'){
					changeKemu1('6');
				}
			}
		}
		else if (type == 'W') {// �⹺
			Fid('tks_string').innerHTML = '��Ӧ�̣�';
			changeOffice(officelist, 'YP', '$in{office_id}','');
			if ($in{Op} == 1){
				changeKemu1('3');
			}
		}else if (type=='B') {//B2B
			Fid('tks_string').innerHTML = 'Office�ţ�';
			changeOffice(officelist, 'B', '$in{office_id}','$old_b2b_user');
			if ($in{Op} == 1){
				changeKemu1('0');
			}
		}else if(type=='ALL'){//ȫ��
			 if ($in{Op} == 1){
				changeKemu1('ALL');
			 }
			
		}else if (type == 'L'){ // B2G
			if ($in{Op} == 1){
				changeKemu1('8');
			 }
		}else if (type == 'T'){ // B2G
			if ($in{Op} == 1){
				changeKemu1('9');
			 }
		}else {//B2C
			Fid('tks_string').innerHTML = '��Դ��';
			changeOffice(officelist, '', '$in{office_id}','');
			if ($in{Op} == 1){
				changeKemu1('2');
			}
		}
		
	}
	var changeOffice = function(data, type, defaultid,default_b2b_user)
	{
		var listobj = Fid('Tk_offices');
		removeAll(listobj);
		var defaultselected = '---- Ʊ֤��Դ ---';
		if (type == 'Z' || type == 'B') {
			defaultselected = '--- Office�� ---';
		}
		listobj[listobj.options.length] = new Option(defaultselected, '');
		var listnum = 1;
		var listcolor = {'P' : 'magenta', 'Y' : 'red', 'Z' : ''};
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
		if (listobj.options.length == 2) {
			listobj.options.selectedIndex = 1;
		}
	}
	// ��ʼ�������������ʱĬ��ֵ
	window.onload = function(){
		mod_tkt(Fid('et_type').value);
	};
	</script>`;
}
if ($in{Order_type} == 2) {	## ������Ʒ
	my $sp_corp_list="<option value='' >��ѡ��Ӧ��</option>";
	$sql=" select Office_type,Office_ID,Office_name from ctninfo..Corp_office where Corp_ID='$Corp_center' order by Office_type,Office_ID ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT) {
			while(@row = $db->ct_fetch) {
				my $office_typename;
				if ($row[0] eq "A") {
					$office_typename="��Ʊ";
				}elsif($row[0] eq "B"){
					$office_typename="����";
				}elsif($row[0] eq "H"){
					$office_typename="�Ƶ�";
				}elsif($row[0] eq "T"){
					$office_typename="��Ʊ";
				}elsif($row[0] eq "V"){
					$office_typename="ǩ֤";
				}
				elsif($row[0] eq "Z"){
					$office_typename="���λ";
				}
				if ($office_typename ne "") {
					$office_typename="��$office_typename��";
				}
				$office_name{$row[1]}="$office_typename".$row[2];
				my $selected="";
				if ($in{Sp_corp_q} eq $row[1]) {
					$selected = "selected = \"selected\"";
				}else{
					$selected = "";
				}
				$sp_corp_list .=qq!<option value="$row[1]" $selected>$office_typename $row[2]</option>!;
			}
		}
	}
	##��ȡ��Ʒ����
	my $pro_list ="<option value=''>ѡ���Ʒ</option>";
	$sql =" select Pro_id,Pro_name from ctninfo..d_inc_pro where Corp_ID in ('SKYECH','$Corp_center') and Status='Y' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		 if($restype==CS_ROW_RESULT)	{
			 while(@row = $db->ct_fetch){
				  my $seleclted;
				 if ($in{pid} == $row[0]) { 	$seleclted=" selected";	 }
				 $pro_list .="<option value='$row[0]' $seleclted>$row[1]</option>";
			 }
		 }
	}
	##ǰ�����ж�����   liangby@2018-3-9
	#<font color=maroon>��ѯ��</font>�����ţ�<input type=text name=Res_ID value="" size=16 />
	print qq!<table border=0 cellpadding=1 cellspacing=0 width=100%>
	<tr><td>\n!;
	print qq!
	��Ա���룺<input name=userid value="$in{userid}" size=16 />
	��ϵ�ˣ�<input type=text size=14 maxlength=32 name=Guest_name value='$in{Guest_name}' >
	��Ӧ�̣�<select name="Sp_corp_q" class="input_txt_select input_txtgy" style='width:130pt;' >$sp_corp_list</select>
	��Ʒ���ͣ�<select name=pid >$pro_list</select>
	</td></tr>
	<tr><td height=1 bgcolor=808080 colspan=2></td></tr>
	</table>\n!;
}
elsif ($in{Order_type} == 4) {## ���
	## ��ѯƱ֤��Դ
	my @office_array = &get_office($Corp_office,"","array","A','H','T','V","","Y");
	my $officelist ="<option value=''>ȫ��</option>";
	my @tmp_office_array = ();
	for (my $i = 0; $i < scalar(@office_array); $i++) {
		if (($office_array[$i]{o_type} eq "A" && $office_array[$i]{type}=~/[YP]/) || $office_array[$i]{o_type}=~/[HTV]/) {	## ��Ʊ���⹺��ƽ̨��Ƶ��Ʊǩ֤
			my $o_type="[��Ʊ]";
			my $sted="";
			if ($office_array[$i]{id} eq $in{Sp_corp}) {
				$sted=" selected";
			}
			if ($office_array[$i]{o_type} eq "H") {	 $o_type="[�Ƶ�]";	}
			elsif ($office_array[$i]{o_type} eq "T") {	 $o_type="[��Ʊ]";	}
			elsif ($office_array[$i]{o_type} eq "V") {	 $o_type="[ǩ֤]";	}
			elsif ($office_array[$i]{o_type} eq "Z") {	 $o_type="[���λ]";	}
			$officelist .="<option value='$office_array[$i]{id}' $sted>$office_array[$i]{id} $office_array[$i]{name} $o_type</option>";
		}
	}
	#�����ţ�<input type=text name=Res_ID value="" size=16 />
	print qq!<table border=0 cellpadding=1 cellspacing=0 width=100%>
	<tr><td>\n!;
	print qq!��Ӧ�̣�<select name='Sp_corp'>$officelist</select>
	�տ��ˣ�<input type=text size=14 maxlength=32 name=Inc_title value='$in{Inc_title}' >
	</td></tr>
	<tr><td height=1 bgcolor=808080 colspan=2></td></tr>
	</table>\n!;
}
print qq~</form>
$down_param
<table border=0 cellpadding=0 cellspacing=0 width=100%>\n~;
## =====================================================================
if ($in{Op} == -1) {
	print "<tr><td colspan=2 height=30><font color=red>��ʾ����ѡ����Ҫ��ѯ�Ķ������ͻ������ѯ�������в�ѯ��";
}
else{
	print "<tr><td valign=top colspan=2>";
	if ($in{Order_type} == 2 || $in{Order_type} == 3) {
		if(($in{Order_type} == 2 && $in{Do_act} eq "W" && ($in{Op} eq 0 || $in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4)) || ($in{Order_type} == 3 && $in{Do_act} eq "W" && ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3))){
			my $retMessage='';
			if ($in{Order_type} == 2 && ($in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4)){ ## ������Ʒ��ˡ�ҵ������ˡ�������ˣ�����ǰ������ jf@2018/5/22
				for ($i=0;$i<$in{t_num};$i++) {
					my	$cb="cb_$i";	my $res_id=$in{$cb};
					if ($res_id ne "") {	## ѡ�еĶ���
						$in{Reservation_ID}=$in{"Reservation_ID_$i"};
						$retMessage .= &inc_account_recv_sp();
					}
				}
			}else{	## �������
				$in{pay_method_num}=sprintf("%.0f",$in{pay_method_num});
				if ($in{pay_method_num}<1) {$in{pay_method_num}=1;}
				##�ж��ظ�ƾ֤��,Ϊ���������ж���������ͬһ����ͬһ��Ŀƾ֤�ű���Ψһ   liangby@2015-6-11
				my @tradeno_check=();
				for (my $p=0;$p<$in{pay_method_num} ;$p++) {##���ָ����Ŀ	fanzy@2015-04-17
					my $pp=($p==0)?"":"_$p";
					my $pay_kemu=$in{"Pay_type".$pp};			#�����Ŀ
					my $pay_bank=$in{"Pay_type2".$pp};		#������Ŀ
					my $p_pingzheng="pingzheng".$pp;              ##ƾ֤��
					if ($in{$p_pingzheng} ne "") {
						push(@tradeno_check,$pay_kemu."&,".$pay_bank."&,".$in{$p_pingzheng});
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
							$error_msg .="��Ŀ:$c_kemu_name";
						}else{
							$error_msg .="��Ŀ:$pay_kemu";
						}
						if ($c_bank_name ne "") {
							$error_msg .=",�����Ŀ:$c_bank_name";
						}elsif($pay_bank ne ""){
							$error_msg .=",�����Ŀ:$pay_bank";
						}
						$error_msg .="������ͬƾ֤��$pingzheng";
					}
					$error_msg .=",ͬһ����������ͬһ��Ŀƾ֤�ű���Ψһ";
					
					print MessageBox("������ʾ","�Բ���$error_msg"); 
					exit;
				}
				for ($i=0;$i<$in{t_num};$i++) {
					my	$cb="cb_$i";	my $res_id=$in{$cb};
					if ($res_id ne "") {	## ѡ�еĶ���
						if($in{refuse_pay} eq "Y"){	##�հ׵��ܾ�����(ֻ�ܵ�������)	linjw@2016-11-18
							$retMessage=&refuse_pay_op("$res_id");
							last;
						}
						$in{Reservation_ID}=$in{"Reservation_ID_$i"};
						$in{old_left_total}=sprintf("%.2f",$in{"old_left_total_$i"});
						$in{recv_total}=sprintf("%.2f",$in{"recv_total_$i"});$in{recv_total}=~ s/\s*\.00//;
						my $bd_recv_total=$in{recv_total};
						for (my $p=0;$p<$in{pay_method_num} ;$p++) {##�����տʽ	fanzy@2015-04-16
							$pp=($p==0)?"":"_$p";
							$p_Pay_type=$in{"Pay_type".$pp};
							$p_Pay_type2=$in{"Pay_type2".$pp};
							$p_ReferNo=$in{"ReferNo".$pp};
							$p_ReOp_date=$in{"ReOp_date".$pp};
							$p_BankName=$in{"BankName".$pp};
							$p_BankCardNo=$in{"BankCardNo".$pp};
							$p_pingzheng=$in{"pingzheng".$pp};              ##ƾ֤��
							$sp_corp=$in{"sp_corp".$pp};
							if ($p_Pay_type eq "1003.01.01" || $p_Pay_type eq "1003.01.02") {
								$p_pingzheng=$p_ReferNo;
								#$Pay_trans=$in{ReOp_date}."|".$in{BankName}."|".$in{BankCardNo};
								$in{Remark}.=" ���ײο���:$p_ReferNo;��������:$p_ReOp_date;������:$p_BankName;���ź�4λ:$p_BankCardNo";
							}else{
							
							}
							$Pay_Rec_tol="Pay_Rec_tol".$pp;
							$in{$Pay_Rec_tol}=sprintf("%.2f",$in{$Pay_Rec_tol});$in{$Pay_Rec_tol}=~ s/\s*\.00//;
							$p_sh_recv=$in{$Pay_Rec_tol};  ##�������ж��õ� liangby@2015-7-8
							my $the_last=$in{pay_method_num}-$p;
							if (($the_last!=1 && $in{$Pay_Rec_tol}==0) || $bd_recv_total==0) {
								next;
							}
							my $once_price=$bd_recv_total;
							my $balance=sprintf("%.2f",($in{$Pay_Rec_tol}-$once_price));$balance=~ s/\s*\.00//;
							if ($the_last!=1 && (($bd_recv_total>0 && $in{$Pay_Rec_tol}>0 && $balance<0) || ($bd_recv_total<0 && $in{$Pay_Rec_tol}<0 && $balance>0))) {
								$once_price=$in{$Pay_Rec_tol};
							}else{
								$once_price=$bd_recv_total;
							}
							$in{$Pay_Rec_tol}=sprintf("%.2f",($in{$Pay_Rec_tol}-$once_price));$in{$Pay_Rec_tol}=~ s/\s*\.00//;
							$bd_recv_total=sprintf("%.2f",($bd_recv_total-$once_price));$bd_recv_total=~ s/\s*\.00//;
							$in{recv_total}=$once_price;
							##������Ʒ�������Ӧ��   liangby@2016-5-20
							$retMessage .= &inc_account_recv_sp();
							$in{old_left_total}=sprintf("%.2f",($in{old_left_total}-$once_price));$in{old_left_total}=~ s/\s*\.00//;
						}
						print qq!<br><br><br>!;
					}
				}
			}
			print &showMessage("ϵͳ��ʾ", "$retMessage ������ɣ�", "/cgishell/golden/admin/airline/res/air_account_fk.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Order_type=$in{Order_type}&Op=$in{Op}&Corp_ID=$in{Corp_ID}&user_book=$in{user_book}&Start=1&air_type=$in{air_type}&Depart_date=$Depart_date&End_date=$End_date&Sender=$in{Sender}&History=$in{History}&pay_obj=$in{pay_obj}&Send_corp=$in{Send_corp}", "", 0, "3000");
			&Footer();
			exit;
		}
		##������Ʒ�������Ӧ��
		&inc_account_sp($in{Op});
	}elsif($in{Order_type} == 1){##��Ʊ��Ӧ�̸���   liangby@2016-7-25
		if($in{Do_act} eq "W" &&($in{Op} eq "0" || $in{Op} eq "1" ||  $in{Op} eq "3" || $in{Op} eq "4" )){
			$retMessage .= &account_recv_sp();
			print &showMessage("ϵͳ��ʾ", "$retMessage ������ɣ�", "/cgishell/golden/admin/airline/res/air_account_fk.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Order_type=$in{Order_type}&Op=$in{Op}&Corp_ID=$in{Corp_ID}&user_book=$in{user_book}&Start=1&air_type=$in{air_type}&Depart_date=$Depart_date&End_date=$End_date", "", 0, "3000");
			&Footer();
			exit;
		}
		&air_account_sp('H',$in{Op});
	}
	elsif ($in{Order_type} == 4 ) {##��/��� wfc@2016-03-27
		if ($in{Operate_type} ne "") {## ������
			print $op_msg=&inc_pay_op();
			print "</font>";
		}
		&inc_pay_list();
	}

}
## =====================================================================
print "</td></tr></table>";

