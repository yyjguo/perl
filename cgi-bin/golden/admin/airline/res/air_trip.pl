#!c:/Perl/bin/Perl.exe
require "ctnlib/golden/common.pl";
require "ctnlib/golden/cgi-lib.pl";
require "ctnlib/golden/html.pl";
require "ctnlib/golden/datelib.pl";
require 'ctnlib/golden/manage.pl';

use Sybase::CTlib;
## =====================================================================
## start program
## =====================================================================
## ---------------------------------------
## Read Post/Get Datas,use cgi-lib.pl
## ---------------------------------------
&ReadParse();
## ---------------------------------------
## Print Html header,use Html.pl
## ---------------------------------------
&Header("�����г̵�");
## =====================================================================
$Corp_ID = ctn_auth("TRIP");
if(length($Corp_ID) == 1) { exit; }
&get_op_type();
## =====================================================================
#��ȡ���԰�
$error_info=&get_local_lan();
if ($error_info ne "OK" ) {
 print "�������԰�ʧ��,$error_info";
 exit;
}
#----------------------------------------------------
## ����������/������
my $cookiehash = {
	trip => $in{trip},
	templateid => $in{templateid},
	cb_a => $in{cb_a},
	cb_c => $in{cb_c},
	print_logo => $in{print_logo},
	classcmt => $in{classcmt},
	cmt => $in{cmt},
	price_nshow => $in{price_nshow},
	associate => $in{associate},
};
my $CGI = new CGI;
%airtrip = $CGI->cookie('airtrip');
my %checkbox = ();
if ($airtrip{cb_a} eq 'A') {
	$checkbox{cb_a} = ' checked';
}
if ($airtrip{cb_c} eq 'C') {
	$checkbox{cb_c} = ' checked';
}
if ($airtrip{print_logo} eq 'Y') {
	$checkbox{print_logo} = ' checked';
}
if ($airtrip{classcmt} eq 'Y') {
	$checkbox{classcmt} = ' checked';
}
if ($airtrip{cmt} eq 'Y') {
	$checkbox{cmt} = ' checked';
}
if ($airtrip{price_nshow} eq 'Y') {
	$checkbox{price_nshow} = ' checked';
}
if ($airtrip{associate} eq 'Y') {
	$checkbox{associate} = ' checked';
}
if ($airtrip{trip} ne '') {
	$checkbox{trip}[$airtrip{trip}] = ' selected';
}


my $templatelist = "<option value=\"\">$SkyLocal{'ѡ��ģ��'}</option>";
$sql = "SELECT Msg_title, Msg_serial FROM ctninfo..City_msg WHERE Corp_ID='$Corp_ID' AND Msg_type='H'";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			my $selected = '';
			if ($airtrip{templateid} eq $row[1]) {
				$selected = ' selected';
			}
			$templatelist .= qq`<option value="$row[1]"$selected>$row[0]</option>`;
		}
	}
}
if ($Corp_type eq "A" && $Corp_TAG =~/V/) {##����   liangby@2013-9-10
}else{
	$mod_url=qq!<li><a href="http://$G_SERVER/cgishell/golden/admin/baseinfo/city_msg.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Op_type=A"><img src="/admin/images/icon_base/icon_002.gif">$SkyLocal{'ά����ʾ��Ϣ'}</a></li>!;
	$mod_url.=qq!<li><a href="http://$G_SERVER/cgishell/golden/admin/baseinfo/city_msg.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Op_type=B"><img src="/admin/images/icon_base/icon_002.gif">$SkyLocal{'ά���г̵�'}LOGO</a></li>!;

}
print qq`
<link rel="stylesheet" type="text/css" href="/admin/style/style.css" />
<script type="text/javascript" src="/admin/js/global.js"></script>
<h1 id="PageHeadtitle"><strong>$SkyLocal{'��Ʊ��̨'}</strong> - $SkyLocal{'�г�ȷ�ϵ�'}</h1>
<div id="append_parent"></div>
<div class="wrapper" id="air_trip">
	<div class="tabNav" id="parameter_tabs">
		<ul>
			<li class="current"><a href="http://$G_SERVER/cgishell/golden/admin/airline/res/air_trip.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}"><img src="/admin/images/icon_base/icon_printer.gif">$SkyLocal{'��ӡ�г�ȷ�ϵ�'}</a></li>
			$mod_url
		</ul>
	</div>
	<dl class="middle">
		<form action="http://$G_SERVER/cgishell/golden/admin/airline/res/air_trip_ok.pl" method="post" name="book" onsubmit="return ver();" target="_blank">
			<dd>$SkyLocal{'������'}��<input type="text" name="resid" class="input-style1" /></dd>
			<dd>$SkyLocal{'��������'}��<input type="text" name="pnr" class="input-style2" maxlength="6" /></dd>
			<dd>$SkyLocal{'Ʊ��'}��<input type="text" name="tkt_id" class="input-style2" maxlength="14" /></dd>
			<dd>$SkyLocal{'��ӡ��ʽ'}��<select name="trip" id="tripstyle" class="input-style2" style="width: 147px;">
				<option value="0"$checkbox{trip}[0]>$SkyLocal{'��ʽһ'}</option>
				<option value="1"$checkbox{trip}[1]>$SkyLocal{'��ʽ��'}��$SkyLocal{'�������ڹ���'}��</option>
				<option value="2"$checkbox{trip}[2]>$SkyLocal{'��ʽ��'}��$SkyLocal{'�ɵ��ڱ߾��ֺ�'}��</option>
				<option value="3"$checkbox{trip}[3]>$SkyLocal{'��ʽ��'}��$SkyLocal{'���͵����г̵�'}��</option>
				<option value="4"$checkbox{trip}[4]>$SkyLocal{'��ʽ��'}��$SkyLocal{'�������ڹ���'}��</option>
				<option value="5"$checkbox{trip}[5]>$SkyLocal{'��ʽ��'}��$SkyLocal{'���ӿ�Ʊ�г̵�'}��</option>
				<option value="6"$checkbox{trip}[6]>$SkyLocal{'��ʽ��'}��$SkyLocal{'�ͻ���ƱǷ�'}��</option>
				<option value="7"$checkbox{trip}[7]>$SkyLocal{'��ʽ��'}��$SkyLocal{'�˷ϵ���Ʊ����'}��</option>
			</select></dd>
			<dd>$SkyLocal{'ģ��'}��<select name="templateid" id="tripstyle" class="input-style2" style="width: 147px;">$templatelist</select></dd>
			<h1>$SkyLocal{'�ر���ʾѡ��'}</h1>
			<dd><label for="cb_c"><input type="checkbox" name='cb_c' id="cb_c" value='C'$checkbox{cb_c} />$SkyLocal{'�������ʱ�̱�'}��$SkyLocal{'��������'}��</label></dd>
			<dd><label for="cb_a"><input type="checkbox" name='cb_a' id="cb_a" value='A'$checkbox{cb_a} />$SkyLocal{'�������ʱ�̱�'}��$SkyLocal{'�ִ����'}��</label></dd>
			<dd><label for="print_logo"><input type="checkbox" name="print_logo" id="print_logo" value="Y"$checkbox{print_logo} />$SkyLocal{'��ӡ��˾��־'}��LOGO��</label></dd>
			<dd><label for="classcmt"><input type="checkbox" name='classcmt' id="classcmt" value='Y'$checkbox{classcmt} />$SkyLocal{'��ӡ�˸�ǩ�涨'}</label></dd>
			<dd><label for="cmt"><input type="checkbox" name='cmt' id="cmt" value='Y'$checkbox{cmt} />$SkyLocal{'��ȡ������ע��Ϣ'}</label></dd>
			<dd><label for="price_nshow"><input type="checkbox" name='price_nshow' id="price_nshow" value='Y'$checkbox{price_nshow} />$SkyLocal{'����ʾ���'}</label></dd>
			<dd><label for="associate"><input type="checkbox" name='associate' id="associate" value='Y'$checkbox{associate} />$SkyLocal{'�Ƿ����������'}</label></dd>
			<dd class="OptionBox">
				<input type="submit" value="$SkyLocal{'ȷ������'}" class="btn_next" />
				<input type="reset" value="$SkyLocal{'��������'}" class="btn_next" />
				<input type="hidden" name="User_ID" value="$in{User_ID}" />
				<input type="hidden" name="Serial_no" value="$in{Serial_no}" />
				<input type="hidden" name="i_num" value="$i" />
			</dd>
		</form>
	</dl>
</div>

<script type="text/javascript">
var cb_a = document.getElementById('cb_a');
var cb_c = document.getElementById('cb_c');
var print_logo = document.getElementById('print_logo');
var classcmt = document.getElementById('classcmt');
var tripstyle = document.getElementById('tripstyle');
var cmt = document.getElementById('cmt');
var price_nshow = document.getElementById('price_nshow');
var associate = document.getElementById('associate');
function ver()
{
	if (document.book.resid.value == '' && document.book.pnr.value == '' && document.book.tkt_id.value == '') {
		alert("$SkyLocal{'�����붩���Ż�PNR���в�ѯ'}��");
		document.book.resid.focus();
		return false;
	}
	setcookie('checkbox_tips_a', cb_a.checked, 3600000, 'http://$G_SERVER/cgishell/golden/admin/airline/res/');
	setcookie('checkbox_tips_c', cb_c.checked, 3600000, 'http://$G_SERVER/cgishell/golden/admin/airline/res/');
	setcookie('checkbox_print_logo', print_logo.checked, 3600000, 'http://$G_SERVER/cgishell/golden/admin/airline/res/');
	setcookie('checkbox_classcmt', classcmt.checked, 3600000, 'http://$G_SERVER/cgishell/golden/admin/airline/res/');
	setcookie('checkbox_cmt', cmt.checked, 3600000, 'http://$G_SERVER/cgishell/golden/admin/airline/res/');
	setcookie('checkbox_price_nshow', price_nshow.checked, 3600000, 'http://$G_SERVER/cgishell/golden/admin/airline/res/');
	setcookie('checkbox_associate', associate.checked, 3600000, 'http://$G_SERVER/cgishell/golden/admin/airline/res/');
	setcookie('select_tripstyle', tripstyle.selectedIndex, 3600000, 'http://$G_SERVER/cgishell/golden/admin/airline/res/');
}
function init() {
	var cb_a_value = getcookie('checkbox_tips_a') == 'false' ? false : true;
	var cb_c_value = getcookie('checkbox_tips_c') == 'false' ? false : true;
	var print_logo_value = getcookie('checkbox_print_logo') == 'false' ? false : true;
	var classcmt_value = getcookie('checkbox_classcmt') == 'false' ? false : true;
	var cmt_value = getcookie('checkbox_cmt') == 'false' ? false : true;
	var price_nshow_value = getcookie('checkbox_price_nshow') == 'false' ? false : true;
	var associate_value = getcookie('checkbox_associate') == 'false' ? false : true;
	var tripstyle_value = getcookie('select_tripstyle') == 'false' ? false : true;
	cb_a.checked = cb_a_value;
	cb_c.checked = cb_c_value;
	print_logo.checked = print_logo_value;
	classcmt.checked = classcmt_value;
	cmt.checked = cmt_value;
	price_nshow.checked = price_nshow_value;
	associate.checked = associate_value;
	tripstyle.selectedIndex = getcookie('select_tripstyle');
	document.book.resid.focus();
}
//init();
</script>
`;

### ��ѯ����˾��������Ϣ
#my $i = 0;
#$sql = "select Msg_title,Msg from ctninfo..City_msg where Corp_ID='$Corp_ID' and Msg_type='O' order by Msg_serial ";
#print "<pre>$sql</pre>";
#$db->ct_execute($sql);
#while($db->ct_results($restype) == CS_SUCCEED) {
#	if($restype==CS_ROW_RESULT) {
#		while(@row = $db->ct_fetch) {
#			print "<tr><td valign=top><input name='cb_$i' type=checkbox value='$row[0]'>$row[0]</td>
#			<td align=right><textarea name='info_$i' cols=88 rows=6 wordwrap=hard style='font-size:9pt;'>$row[1]</textarea></td></tr>";
#			$i ++;
#		}
#	}
#}

## =====================================================================
## print tailer
## =====================================================================
&Footer();