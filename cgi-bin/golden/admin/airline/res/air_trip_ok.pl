#!c:/Perl/bin/Perl.exe
require "ctnlib/golden/common.pl";
require "ctnlib/golden/cgi-lib.pl";
require "ctnlib/golden/html.pl";
require "ctnlib/golden/datelib.pl";
require "ctnlib/golden/manage.pl";
require "ctnlib/golden/air_res.pl";
require "ctnlib/golden/eProxy.pl";

use Sybase::CTlib;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use CGI qw/:standard/;
use CGI::Cookie;
## =====================================================================
## start program
## =====================================================================
## ---------------------------------------
## Read Post/Get Datas,use cgi-lib.pl
## ---------------------------------------
&ReadParse();
#&Header();
## =====================================================================
$Corp_ID = ctn_auth("");
if(length($Corp_ID) == 1) { exit; }
&get_op_type();
## =====================================================================
## 服务器域名/主机名
my $servername = $ENV{SERVER_NAME} ne '' ? $ENV{SERVER_NAME} : $ENV{HTTP_HOST};
#$servername =~ s/^.+?\.//g;
$template_corp=$Corp_center;   ##模板所属   liangby@2014-9-11
if ($Corp_type eq "A" && $Is_delivery ne "Y") {
	$template_corp=$Corp_ID;
}
if ($in{templateid} eq "") {##默认使用自定义的模板   liangby@2014-3-11
	$db = &connect_database();
	$sql = "SELECT Msg_serial FROM ctninfo..City_msg WHERE Corp_ID='$template_corp' AND Msg_type='H'";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				if ($in{templateid} eq "") {
					$in{templateid}=$row[0];
					$in{cmt}="Y";
				}
				
			}
		}
	}
}

my $CGI = new CGI;
%airtrip = $CGI->cookie('airtrip');
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
my $cookie = new CGI::Cookie(-name=>'airtrip', -value=> $cookiehash, -expires => '+1M', -domain => $servername, -path => '/cgishell/golden/admin/airline/res/');
print $CGI->header(-cookie=>[$cookie], -charset => 'gb2312');
&Header('', 'N');

my $today = &cctime(time);
($week,$month,$day,$time,$year)=split(" ",$today);
if($day<10){$day="0".$day;}
my $t_date = $month.$day;		my $today = "$year年$month月$day日";

## 初始化，从cookie里读取
if ($in{cb_a} eq '') {
	$in{cb_a} = $airtrip{cb_a};
}
if ($in{cb_c} eq '') {
	$in{cb_c} = $airtrip{cb_c};
}
if ($in{print_logo} eq '') {
	$in{print_logo} = $airtrip{print_logo};
}
if ($in{classcmt} eq '') {
	$in{classcmt} = $airtrip{classcmt};
}
if ($in{trip} eq '') {
	$in{trip} = $airtrip{trip};
}
if ($in{templateid} eq '') {
	$in{templateid} = $airtrip{templateid};
}
if ($in{cmt} eq '') {
	$in{cmt} = $airtrip{cmt};
}
if ($in{price_nshow} eq '') {
	$in{price_nshow} = $airtrip{price_nshow};
}
if ($in{associate} eq ''){ 
	$in{associate} = $airtrip{associate};
}
my $insertText = '';
my $editorColor = '#9DC0FF';
if ($User_type eq 'C') {
	$insertText = 'return;';
	$editorColor = '';
}
my $price_nshow=($in{price_nshow} eq "Y")?" style='display:none;'":"";
my $price_nshows=($in{price_nshow} eq "Y")?"display:none;":"";
##客户机票欠款单 hecf 2014/5/8
if($in{trip} eq '6'){
	$in{pnr} =~ tr/a-z/A-Z/;
	#从缓存服务器读取 wfc@2013-05-05
	my $post_url = "http://$G_SERVER/cgishell/client/air_info1.pl";
	my $ua = LWP::UserAgent->new();
	$ua->agent('Mozilla/5.0');
	$req = POST $post_url,
	[ ID =>"$in{resid}",
	PNR =>"$in{pnr}",
	User_ID => "$in{User_ID}",
	Serial_no =>"$in{Serial_no}"];
	my $content;
	my $response=$ua->request($req);
	if ($response->is_success) {
		$content=$response->content;
		if ($content eq "N") {
			print &showMessage("错误提示", "您输入的订座记录编号无效！", "goback", "", 2, "");
			&Footer();
			exit;
		}
		$g_u_contact = @{&getXMLValue("u_contact",$content)}[0];
		$g_book_type = @{&getXMLValue("book_type",$content)}[0];
		$g_u_address = @{&getXMLValue("u_address",$content)}[0];
		$g_booktime = @{&getXMLValue("booktime",$content)}[0];
		$g_logo = @{&getXMLValue("logo",$content)}[0];
		$g_c_name = @{&getXMLValue("c_name",$content)}[0];
		$g_c_home = @{&getXMLValue("c_home",$content)}[0];
		$g_u_corp = @{&getXMLValue("u_corp",$content)}[0];
		$g_u_time = @{&getXMLValue("u_time",$content)}[0];
		$g_u_tel = @{&getXMLValue("u_tel",$content)}[0];
		$g_other = @{&getXMLValue("other",$content)}[0];
		$g_guest = @{&getXMLValue("guest",$content)}[0];
		$g_total = @{&getXMLValue("total",$content)}[0];
		$g_pnr1 = @{&getXMLValue("pnr1",$content)}[0];
		$g_pay = @{&getXMLValue("pay",$content)}[0];
		$g_big = @{&getXMLValue("big",$content)}[0];
		$g_ID = @{&getXMLValue("ID",$content)}[0];

		$g_logo = $g_logo eq '' ? '' : "<img height='32px' src='$g_logo'/>";
		

		$Is_print = 'Y';
	}else {
		my $responses=$response->status_line;
		print &showMessage("错误提示", "服务器连接失败,订座记录获取失败！", "goback", "", 2, "");
		&Footer();
		exit;
	}
	print qq`
	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
	<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
	<meta http-equiv="Content-Type" content="text/html; charset=gb2312" />
	<title>客户机票欠款单</title>
	<script type="text/javascript" src="/admin/js/global.js"></script>
	<script language="javascript" src="/admin/js/ajax/jquery-1.3.2.min.js"></script>
	<script type="text/javascript" src="/admin/js/popwin.js"></script>
	<div id="append_parent"></div>
	<script language="javascript">
		var wayshow={};wayshow.seek="no";wayshow.folder="no";wayshow.look="litimg";wayshow.order="mtime";wayshow.ordermm="desc";wayshow.img="off";wayshow.Type="triplogo";
		function OnUploadCompleted(errorNumber, fileUrl, fileName, customMsg){
			document.getElementById("corp_logo").src=fileUrl;
			pmwin('close');
		}
	</script>
	<input type="hidden" name="URL" id="URL" value="http://$G_WEBSITES/attach/$Corp_center/triplogo/"/>
	<script type="text/javascript">
		function printInv(){
			changeShow();
			if ("$Is_print"!="Y") {
				\$.getJSON("/cgishell/golden/admin/manage/get_ffp.pl?callback=?", {User_ID:"$in{User_ID}",Serial_no:"$in{Serial_no}",Form_type:"air_trip",resid:"$in{resid}"},
				function(data) {
					var Isreturn=data['air_trip'];//0:订单号为空;1:无此订单;2:该订单已标记打印;3:打印标记成功;4:打印标记失败
					printInv1();
				});
			}else{
				printInv1();
			}
		}
		function printInv1(){
			var marginTop = document.getElementById("layerbox").style.pixelTop;
			var marginLeft = document.getElementById("layerbox").style.pixelLeft;
			setcookie('marginTop', marginTop, 864000, '', '', '');
			setcookie('marginLeft', marginLeft, 864000, '', '', '');
			
			if(Fid('tab_content_1')) setcookie('tab_content_1', Fid('tab_content_1').style.fontSize, 864000, '', '', '');
			if(Fid('tab_content_2')) setcookie('tab_content_2', Fid('tab_content_2').style.fontSize, 864000, '', '', '');
			if(Fid('tab_content_3')) setcookie('tab_content_3', Fid('tab_content_3').style.fontSize, 864000, '', '', '');
			if(Fid('tab_content_4')) setcookie('tab_content_4', Fid('tab_content_4').style.fontSize, 864000, '', '', '');
			if(Fid('tab_content_5')) setcookie('tab_content_5', Fid('tab_content_5').style.fontSize, 864000, '', '', '');
			if(Fid('tab_content_6')) setcookie('tab_content_6', Fid('tab_content_6').style.fontSize, 864000, '', '', '');
			window.print();
		}

		//键盘操作部分
		function showmargin() {
			document.getElementById("showmargin").innerHTML = "左边距：" + document.getElementById("layerbox").style.pixelLeft + " px<br>上边距：" + document.getElementById("layerbox").style.pixelTop + " px";
		}

		var timer,X,Y;
		function moveItem(x,y) {
			document.getElementById("layerbox").style.pixelTop += y;
			document.getElementById("layerbox").style.pixelLeft += x;
			showmargin();
		}
		// 键盘事件： 上38 / 下40 / 左37 / 右39
		function ctrlMove() {
			switch(event.keyCode)
			{
				case 37:
					moveItem(-1,0);
					break;
				case 38:
					moveItem(0,-1);
					break;
				case 39:
					moveItem(1,0);
					break;
				case 40:
					moveItem(0,1);
					break;
			}
		}
		function init() {
			var marginTop = getcookie('marginTop');
			var marginLeft = getcookie('marginLeft');
			if (marginTop) {
				document.getElementById("layerbox").style.pixelTop = marginTop;
			}
			if (marginLeft) {
				document.getElementById("layerbox").style.pixelLeft = marginLeft;
			}
			showmargin();
			for (var i = 1; i < 7; i++) {
				try {
					Fid('tab_content_' + i).style.fontSize = getcookie('tab_content_' + i);
				}
				catch(e){};
			}
		}

		// 插入输入对象
		function insertText(e, type) {
			$insertText
			var parentObj = e.parentNode;
			var objText = e.innerHTML;
			objText = objText.replace(/<br>/gi, "\\n");
			var objId = e.id + type;
			var sObj = document.getElementById(objId);
			if (type == 1)
			{
				e.style.display = 'none';
				if (!sObj)
				{
					var element = document.createElement('input');
					element.className = 'group';
					element.id = objId;
					element.value = objText;
					element.title = '输入完成按回车键';
					element.onblur = function () { setValue.call(this, e); };
					element.onkeypress = function () { if(event.keyCode==13) { setValue.call(this, e); } };
					parentObj.appendChild(element);
					document.getElementById(objId).select();
				}
				else {
					sObj.style.display = '';
					sObj.value = objText;
					sObj.title = '输入完成按回车键';
					sObj.select();
					sObj.onblur = function () { setValue.call(this, e); };
					sObj.onkeypress = function () { if(event.keyCode==13) { setValue.call(this, e); } };
				}
			}
			else if (type == 2)
			{
				e.style.display = 'none';
				if (!sObj) {
					var element = document.createElement('textarea');
					element.className = 'grouparea';
					element.id = objId;
					var elementText = document.createTextNode(objText);
					element.onblur = function () { setValue.call(this, e); };
					element.appendChild(elementText);
					parentObj.appendChild(element);
					document.getElementById(objId).select();
				}
				else {
					sObj.style.display = '';
					sObj.value = objText;
					sObj.select();
					sObj.onblur = function () { setValue.call(this, e); };
				}
			}
		}
		// 设置为输入的文本
		function setValue(e) {
			var v = this.value;
			v = v.replace(/\\n/g, "<br>");
			e.style.display = '';
			e.innerHTML = v;
			this.style.display = 'none';
		}

		// 隐藏元素
		function closeItem (e) {
			var item = document.getElementById(e);
			item.style.display = 'none';
		}

		var curfontsize = 14;
		var curlineheight = 16;
		function fontZoom(option, obj){
			if (obj.style.fontSize == '') {
				curfontsize = 14;
				curlineheight = 16;
			}
			if (option == 'down') {
				if(curfontsize > 8){
					obj.style.fontSize = (--curfontsize) + 'px';
					obj.style.lineHeight = (--curlineheight) + 'px';
				}
			}
			else if (option == 'up') {
				if(curfontsize < 18){
					obj.style.fontSize = (++curfontsize) + 'px';
					obj.style.lineHeight = (++curlineheight) + 'px';
				}
			}
			else {
				obj.style.fontSize = '';
				obj.style.lineHeight = '';
			}
		}

		/*addby hecf 2014/5/13*/
		function changeInput(object){
			object.nextSibling.innerHTML=object.value;
		}
		/*改变现实样式*/
		function changeShow(){
			var object = document.getElementById("changeShowID");
			if(object.checked){
				document.getElementById("append_css").innerHTML="";
			}else{
				document.getElementById("append_css").innerHTML="<style type='text/css' media='print'>.screenCss{display:none;}</style>";
			}
		}
		/*输入框失查询*/
		function searchForm(object) {
			if(confirm("重新查询？")){
				if(object.value==''){
					alert("查询值不能为空！");
					return;
				}
				var turnForm = document.createElement("form");
				document.body.appendChild(turnForm);
				turnForm.name = 'searchform';
				turnForm.method = 'post';
				turnForm.action = 'air_trip_ok.pl';
				turnForm.target = '_self';

				var newElement = document.createElement("input");
				newElement.setAttribute("name","trip");
				newElement.setAttribute("type","hidden");
				newElement.setAttribute("value","$in{trip}");
				turnForm.appendChild(newElement);

				var newElement = document.createElement("input");
				newElement.setAttribute("name",object.name);
				newElement.setAttribute("type","hidden");
				newElement.setAttribute("value",object.value);
				turnForm.appendChild(newElement);
				
				var newElement = document.createElement("input");
				newElement.setAttribute("name","User_ID");
				newElement.setAttribute("type","hidden");
				newElement.setAttribute("value","$in{User_ID}");
				turnForm.appendChild(newElement);

				var newElement = document.createElement("input");
				newElement.setAttribute("name","Serial_no");
				newElement.setAttribute("type","hidden");
				newElement.setAttribute("value","$in{Serial_no}");
				turnForm.appendChild(newElement);
				turnForm.submit();
			}

		}

	</script>
	<style type="text/css" media="print">
	/* media="print" 这个属性可以在打印时有效 */
	/* 不打印 */
	.Noprint{ display: none; }
	/* 分页 */
	.PageNext{ page-break-after: always; }
	</style>

	<!--页面样式-->
	<style type="text/css" media="print">
	.w_send{width:500px;}
	.w_k{width:260px;fload:left;text-align:left;}
	.w-w{width:370px;}
	.inputValue{display:none;}
	.bill{width:770px;height:250px;margin:0px;}
	.lines{width:770px;}
	table th{font-weight:300;}
	.getInputValue{display:inline;margin:0px;font-size:9pt;}
	</style>
	<style type="text/css" media="screen">
	.w_send{width:680px;}
	.w_k{width:310px;fload:left;text-align:left;}
	.w-w{width:500px;}
	.getInputValue{display:none;}
	.bill{width:903px;height:370px;padding:3px;}
	.lines{width:903px;}
	.c_blue{color:blue;}
	.c_red{color:red;}
	.font-22{font-size:18pt;}
	.font-18{font-size:14pt;}
	</style>
	<style type="text/css" media="all">
	textarea,input{font-size:9pt}
	p{margin:0px;padding:0px;}
	body{font-family:"宋体";font-size:10pt;}
	span{ text-align:center; float:left; margin:2px auto;}
	.m-l-10{margin-left:10px;}
	.t_a_l{text-align:left;}
	.w_200{width:200px;}
	.lines{text-align:center;clear:both;}
	.h_32{line-height:32px;}
	.f_left{float:left;}
	.f_right{float:right;}
	.w-100{width:100%;}
	.w-15{width:15%;}
	.w-13{width:13%;}
	.w-10{width:10%;}
	.w-7{width:7%;}
	.w-5{width:5%;}
	.font-9{font-size:9pt;}
	.screenCss{fload:left;}
	</style>
	<!--页面样式end-->

	<style type="text/css" media="screen">
	.wrapper {
		background: #f4f4f4;
	}
	.operation {
		margin: 0px auto;
		text-align: center;
		background: #FFFAD8;
		border: #FFD35D solid 1px;
	}
	.operation button {
		margin: 2px;
		width: 80px;
		cursor: pointer;
	}
	.group { width: 100px; padding: 1px; }
	.grouparea { width: 350px; height: 50px; }
	.editor { background: $editorColor; }
	</style>
	
	<style type="text/css" media="all">
	body {margin: 0px; }
	h1, h2, ul, li { margin: 0; padding: 0; }
	ul, li { list-style: none; }
	em {
		font-style: normal;
		font-family: Geneva, Helvetica;
	}
	strong { font-family: 黑体; font-weight: normal; font-size: 15px; }
	.content { border: #000 solid 0px; height: 903px; }
	.tcktitle {
		width: 100%;
		overflow: hidden;
	}
	h1 {
		text-align: center;
		font-family: 黑体;
		font-size: 25px;
		font-weight: normal;
	}
	h2 {
		text-align: center;
		font-size: 20px;
		margin-bottom: 8px;
	}
	
	.tips { padding: 3px; text-align: left; font-size: 12px; }
	.operation_menu { display: block; margin-left: 903px; width: 80px; border: #cae1ff solid 1px; text-align: center; }
	.operation_menu li, .operation_menu li a { display: block; clear: both; zoom: 1; }
	.operation_menu li a { padding: 5px; }
	.operation_menu li a:link, .operation_menu li a:visited { text-decoration: none; color: #666; }
	.operation_menu li a:hover { background: #f4fbff; color: #090 }
	</style>
	<div id="append_css"></div>
	</head>
		
	<body onKeyDown="ctrlMove();" onload="init()">
	<div id="layerbox" style="z-index: 100; width: 912px; position: absolute;">
		<div id="layOutDiv"></div>
		<div class="wrapper">
			<div class="bill">
				<p class="lines">
					<span class="f_left">$g_logo</span>
					<span class="f_left c_blue font-18 w_200 t_a_l">$g_c_name</span>
					<span class="font-22 c_red w-w">客 户 机 票 欠 款 单</span>
					<span class="f_right w_200"><label class='screenCss f_left'>受理时间：</label><label class='f_left font-9'> $g_booktime </label></span>
				</p>
				<p class="lines">
					<span  class="f_left c_blue w_200 t_a_l">$g_c_home</span>
					<span class='font-18 w-w'>【 $g_pay 】</span>
					<span class="f_right c_blue w_200"><label class='screenCss f_left'>受理编号：</label><input name="resid" onblur="searchForm(this);" onkeyup="changeInput(this);" class="inputValue" size="17" type="text" value="$g_ID" /><label style="width:120px;" class="getInputValue f_left t_a_l"/>$g_ID</label></span>
				</p>
				<p class="lines">
					<span class="f_right c_blue w_200"><label class='screenCss f_left'>记录编号：</label><input name="pnr" onblur="searchForm(this);" onkeyup="changeInput(this);" class="inputValue" size="17" type="text" value="$g_pnr1" /><label style="width:120px;" class="getInputValue f_left t_a_l"/>$g_pnr1</label></span>
				</p>
				<p class="lines">
					<span class="w_k"><label class='screenCss f_left'>客&nbsp;&nbsp;&nbsp;&nbsp;户：</label><input onkeyup="changeInput(this);" class="inputValue" size="38" type="text" value="$g_u_corp" /><label style="width:190px;" class="getInputValue f_left t_a_l"/>$g_u_corp</label></span>
					<span class="w_k m-l-10"><label class='screenCss f_left'>联	系	人：</label><input onkeyup="changeInput(this);" class="inputValue" size="38" type="text" value="$g_u_contact" /><label style="width:190px;" class="getInputValue f_left t_a_l"/>$g_u_contact</label></span>
					<span class="f_right w_200"><label class='screenCss f_left'>联系电话：</label><input onkeyup="changeInput(this);" class="inputValue" size="17" type="text" value="$g_u_tel" /><label style="width:120px;" class="getInputValue f_left t_a_l"/>$g_u_tel</label></span>
				</p>
				<p class="lines">
					<span class="f_left t_a_l w_send"><label class='screenCss f_left'>送票地址：</label><input onkeyup="changeInput(this);" class="inputValue" style="width:600px;" type="text" value="$g_u_address" /><label style="width:420px;" class="getInputValue f_left t_a_l"/>$g_u_address</label></span>
					<span class="f_right w_200"><label class='screenCss f_left'>送达时间：</label><input onkeyup="changeInput(this);" class="inputValue" size="17" type="text" value="$g_u_time" /><label style="width:120px;" class="getInputValue f_left t_a_l"/>$g_u_time</label></span>
				</p>
				<p class="lines">
					<span class="f_left"><label class='screenCss f_left'>客人姓名：</label><textarea onkeyup="changeInput(this);" style="height:50px;width:822px; vertical-align:top; resize: none;" class="inputValue">$g_guest</textarea><label style="width:700px;" class="getInputValue f_left t_a_l"/>$g_guest</label></span>
				</p>
				<p class="lines">
					<table class="w-100" border='0'>
					 <tr>
					  <th class='w-10'><label class='screenCss'>出发</label></th>
					  <th class='w-10'><label class='screenCss'>抵达</label></th>
					  <th class='w-15'><label class='screenCss'>乘机日期</label></th>
					  <th class='w-10'><label class='screenCss'>航班号</label></th>
					  <th class='w-15'><label class='screenCss'>起飞降落时间</label></th>
					  <th class='w-5'><label class='screenCss'>舱位</label></th>
					  <th class='w-10'$price_nshow><label class='screenCss'>机票款</label></th>
					  <th class='w-7'$price_nshow><label class='screenCss'>保险费</label></th>
					  <th class='w-5'$price_nshow><label class='screenCss'>数量</label></th>
					  <th class='w-13'$price_nshow><label class='screenCss'>欠款合计</label></th>
					 </tr>`;
					my $i=1;
					while($i<=4){
						my ($g_depart1,$g_arrive1,$g_date1,$g_flight1,$g_time1,$g_tax1,$g_yq1,$g_price1,$g_Ticket_money,$g_other1,$g_class1,$g_num1,$g_total1);
						$g_depart1 = @{&getXMLValue("depart$i",$content)}[0];
						$g_arrive1 = @{&getXMLValue("arrive$i",$content)}[0];
						$g_date1 = @{&getXMLValue("date$i",$content)}[0];
						$g_flight1 = @{&getXMLValue("flight$i",$content)}[0];
						$g_time1 = @{&getXMLValue("time$i",$content)}[0];
						$g_tax1 = @{&getXMLValue("tax$i",$content)}[0];
						$g_yq1 = @{&getXMLValue("yq$i",$content)}[0];
						$g_price1 = @{&getXMLValue("price$i",$content)}[0];
						$g_Ticket_money = $g_tax1+$g_yq1+$g_price1 eq 0? '' : $g_tax1+$g_yq1+$g_price1;
						$g_other1 = @{&getXMLValue("other$i",$content)}[0];
						$g_class1 = @{&getXMLValue("class$i",$content)}[0];
						$g_num1 = @{&getXMLValue("num$i",$content)}[0];
						$g_total1 = @{&getXMLValue("total$i",$content)}[0];
						print qq`
						 <tr align=center>
						  <td><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_depart1" /><label class="getInputValue"/>$g_depart1</label></td>
						  <td><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_arrive1" /><label class="getInputValue"/>$g_arrive1</label></td>
						  <td><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_date1" /><label class="getInputValue"/>$g_date1</label></td>
						  <td><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_flight1" /><label class="getInputValue"/>$g_flight1</label></td>
						  <td><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_time1" /><label class="getInputValue"/>$g_time1</label></td>
						  <td><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_class1" /><label class="getInputValue"/>$g_class1</label></td>
						  <td$price_nshow><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_Ticket_money" /><label class="getInputValue"/>$g_Ticket_money</label></td>
						  <td$price_nshow><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_other1" /><label class="getInputValue"/>$g_other1</label></td>
						  <td$price_nshow><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_num1" /><label class="getInputValue"/>$g_num1</label></td>
						  <td$price_nshow><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_total1" /><label class="getInputValue"/>$g_total1</label></td>
						 </tr>`;
						$i++
					}
					print qq`
					 <tr align=center$price_nshow>
					  <td><label class='screenCss'>付款方式</label></td>
					  <td colspan='2'><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_pay" /><label class="getInputValue"/>$g_pay</label></td>
					  <td><label class='screenCss'>其他费用</label></td>
					  <td><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_other" /><label class="getInputValue"/>$g_other</label></td>
					  <td><label class='screenCss'>总计</label></td>
					  <td colspan='3'><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_big" /><label class="getInputValue"/>$g_big</label></td>
					  <td><input onkeyup="changeInput(this);" class="w-100 inputValue" type="text" value="$g_total" /><label class="getInputValue"/>$g_total</label></td>
					 </tr>
					</table>
				</p>
				<p class="lines">
					<span class="f_left m-l-10" style="margin-right:150px;">客户签收</span>
					<span>复核</span>
				</p>
			</div>
		</div>
		
		<div class="operation Noprint">
			<table border="0" cellspacing="0" cellpadding="0" width="100%">
				<tr>
					<td>
						<button onclick="moveItem(0,-4);">上 移 ↑</button><br>
						<button onclick="moveItem(-4,0);">左 移 ←</button>
						<button onclick="moveItem(0,4);">下 移 ↓</button>
						<button onclick="moveItem(4,0);">右 移 →</button>	
					</td>
					<td width="400">
						<div class="tips">
							提　示：<font color="red">受理编号（订单号）或记录编号（订座编码）改变可重新查询。</font><br />
							请先把浏览器“打印设置”的边距均调为0。<br />　　　　
							灰色背景为打印部分，您可以使用键盘方向键进行微调！<br />　　　　
							蓝色背景的文字可点击修改。<br />　　　　
							关闭浏览器后需要重新设置打印边距。<br />　　　　
							</div>
						<div class="tips" id="showmargin">左边距：10px<br />上边距：0px</div>
					</td>
						<td><input id='changeShowID' type='checkbox' onclick="changeShow();" checked=checked>是否打印全部</td>
					<td><button onclick="printInv()">直接打印</button></td>
				</tr>
			</table>
			<iframe frameborder="0" id="frm_update" width="0" style="display: none;"></iframe>
		</div>
	</div>
	<ul class="operation_menu Noprint" id="caption1_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_1'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_1'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_1'));">x 恢复默认</a></li>
	</ul>
	<ul class="operation_menu Noprint" id="caption2_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_2'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_2'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_2'));">x 恢复默认</a></li>
	</ul>
	<ul class="operation_menu Noprint" id="caption3_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_3'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_3'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_3'));">x 恢复默认</a></li>
	</ul>
	<ul class="operation_menu Noprint" id="caption4_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_4'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_4'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_4'));">x 恢复默认</a></li>
	</ul>
	<ul class="operation_menu Noprint" id="caption5_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_5'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_5'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_5'));">x 恢复默认</a></li>
	</ul>`;
	&Footer();
	exit;
}
print qq`
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=gb2312" />
<title>机票行程提醒单</title>
<script type="text/javascript" src="/admin/js/global.js"></script>
<script language="javascript" src="/admin/js/ajax/jquery-1.3.2.min.js"></script>`;

if ($in{resid} ne "") {
	$in{resid} =~ tr/a-z/A-Z/;
	$sql = "select a.Contact,rtrim(a.Usertel),rtrim(a.Userbp),rtrim(a.Reservation_ID),b.Corp_csname,b.Tel,
			b.Logo_gif,b.Homepage,a.Adult_num+a.Child_num+a.Baby_num,a.Book_status,a.Air_type,
			a.Booking_ref,convert(char(10),a.Ticket_time,102),a.Out_total+a.Other_fee+a.Insure_out+isnull(a.Service_fee,0), b.Corp_type,
			a.User_address,convert(char(10),a.S_date,102)+ ' '+ a.S_time,a.Is_reward,a.User_ID,a.Sender_ID,a.Comment,
			b.Fax,b.Address,b.Corp_cname,a.Is_print,convert(char,a.Ticket_time,106),a.Pay_user,a.Alert_status,isnull(a.Service_fee,0),
			a.Agt_total+isnull(a.Service_fee,0)
		from ctninfo..Airbook_$Top_corp a,
			ctninfo..Corp_info b
		where a.Corp_ID=b.Corp_ID
			and a.Reservation_ID='$in{resid}' ";
	if ($Corp_type eq "A" && ($Corp_TAG=~/V/ || $Is_delivery ne "Y")) {##分销   liangby@2013-9-10
		$sql .=" and a.Corp_ID='$Corp_ID' ";
	}
	$in{resid} ="";
}
elsif ($in{pnr} ne "") {
	$in{pnr} =~ tr/a-z/A-Z/;
	$sql = "select a.Contact,rtrim(a.Usertel),rtrim(a.Userbp),rtrim(a.Reservation_ID),b.Corp_csname,b.Tel,
			b.Logo_gif,b.Homepage,a.Adult_num+a.Child_num+a.Baby_num,a.Book_status,a.Air_type,
			a.Booking_ref,convert(char(10),a.Ticket_time,102),a.Out_total+a.Other_fee+a.Insure_out+isnull(a.Service_fee,0), b.Corp_type,
			a.User_address,convert(char(10),a.S_date,102)+ ' '+ a.S_time,a.Is_reward,a.User_ID,a.Sender_ID,a.Comment,
			b.Fax,b.Address,b.Corp_cname,a.Is_print,convert(char,a.Ticket_time,106),a.Pay_user,a.Alert_status,isnull(a.Service_fee,0),
			a.Agt_total+isnull(a.Service_fee,0)
		from ctninfo..Airbook_$Top_corp a,
			ctninfo..Corp_info b
		where a.Corp_ID=b.Corp_ID 
			and a.Booking_ref='$in{pnr}' 
			and a.Book_time > = dateadd(day,-30,getdate()) and a.Book_time < = getdate() ";	
	if ($Corp_type eq "A" && ($Corp_TAG=~/V/ || $Is_delivery ne "Y")) {##分销   liangby@2013-9-10
		$sql .=" and a.Corp_ID='$Corp_ID' ";
	}
}
elsif ($in{tkt_id} ne "") {
	$in{tkt_id}=~ s/\-//g;
	$in{tkt_id}=sprintf("%.0f",$in{tkt_id});
	$tk_id=$in{tkt_id};
	if (length($tk_id)==13) {
		$tk_id=substr($tk_id,-10);
	}
	$sql = "select a.Contact,rtrim(a.Usertel),rtrim(a.Userbp),rtrim(a.Reservation_ID),b.Corp_csname,b.Tel,
			b.Logo_gif,b.Homepage,a.Adult_num+a.Child_num+a.Baby_num,a.Book_status,a.Air_type,
			a.Booking_ref,convert(char(10),a.Ticket_time,102),a.Out_total+a.Other_fee+a.Insure_out+isnull(a.Service_fee,0), b.Corp_type,
			a.User_address,convert(char(10),a.S_date,102)+ ' '+ a.S_time,a.Is_reward,a.User_ID,a.Sender_ID,a.Comment,
			b.Fax,b.Address,b.Corp_cname,a.Is_print,convert(char,a.Ticket_time,106),a.Pay_user,a.Alert_status,isnull(a.Service_fee,0),
			a.Agt_total+isnull(a.Service_fee,0)		--29
		from ctninfo..Airbook_$Top_corp a,
			ctninfo..Corp_info b,
			ctninfo..Airbook_detail_$Top_corp g
		where a.Corp_ID=b.Corp_ID 
			and a.Reservation_ID=g.Reservation_ID
			and g.Ticket_ID=$tk_id ";	
	if ($Corp_type eq "A" && ($Corp_TAG=~/V/ || $Is_delivery ne "Y")) {##分销   liangby@2013-9-10
		$sql .=" and a.Corp_ID='$Corp_ID' ";
	}
}
else{
	print &showMessage("错误提示", "请输入订单号或订座记录编号！", "goback", "", 2, "");
	&Footer();
	exit;
}
#print "<pre>$sql</pre>";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			$contact=$row[0];		$Usertel=$row[1];	$Usermb=$row[2];
			$in{resid} = $row[3];	$corp_name=$row[4];	$corp_tel=$row[5];
			$corp_logo=$row[6];		$homepage=$row[7];
			if ($Usertel eq $corp_tel) {	$Usertel = "";	}
			if ($Usermb eq $corp_tel) {	$Usermb = "";	}
			if ($Usermb eq $Usertel) {	$Usertel = "";	}
			if ($Usertel ne "")	{	$User_tel = $Usertel;	}
			if ($Usermb ne "")	{	$User_tel .= $Usermb;	}
			if ($User_tel eq "") {	$User_tel = "____________";		}
			$person_num=$row[8];	$bk_status=$row[9];
			$Is_inter=$row[10];		$pnr=$row[11];		$tkt_date=$row[12];
			if($Is_inter eq "Y" && $center_airparm =~/q/){
				$Total=sprintf("%.2f",$row[29]);	
			}else{
				$Total=sprintf("%.2f",$row[13]);	
			}
			$this_corptype = $row[14];
			$useraddress=$row[15];	$dev_time=$row[16];	$is_reward=$row[17];
			$book_user=$row[18];	$dev_user=$row[19];
			$comment=$row[20];		$corp_fax=$row[21];	$corp_addr=$row[22];
			$corp_fullname=$row[23];$Is_print=$row[24];
			$pay_user=$row[26];
			$Alert_status=$row[27];
			$Service_fee=sprintf("%.2f",$row[28]);
			## 从订单读取备注信息 jeftom @2011-3-8
			if ($in{cmt} ne 'Y') {
				$comment = '----';
			}
		}
	}
}
my $air_post_xml="";
if ($in{resid} eq "") {#fanzy@2014-04-01
	if ($in{pnr} ne "") {
		my $m_url="http://$G_SERVER/cgishell/client/air_voucher.pl";
		my $ua = LWP::UserAgent->new();
		$ua->agent('Mozilla/5.0');
		my $reqs = POST $m_url,
			[
			User_ID => "$in{User_ID}",
			Serial_no =>"$in{Serial_no}",
			OP =>"RT",
			PNR =>"$in{pnr}",
			];
		my $response=$ua->request($reqs);
		if ($response->is_success) {
			$air_post_xml=$response->content;
			if ($air_post_xml eq "N") {
				print &showMessage("错误提示", "您输入的订座记录编号无效！", "goback", "", 2, "");
				&Footer();
				exit;
			}elsif($air_post_xml eq "C"){
				print &showMessage("错误提示", "您输入的订座记录编号已取消！", "goback", "", 2, "");
				&Footer();
				exit;
			}
		}else {
			my $responses=$response->status_line;
			print &showMessage("错误提示", "服务器连接失败,订座记录获取失败！", "goback", "", 2, "");
			&Footer();
			exit;
		}
	}elsif ($in{tkt_id} ne "") {
		my $m_url="http://$G_SERVER/cgishell/client/air_detr.pl";
		my $ua = LWP::UserAgent->new();
		$ua->agent('Mozilla/5.0');
		my $reqs = POST $m_url,
			[
			User_ID => "$in{User_ID}",
			Serial_no =>"$in{Serial_no}",
			TKID =>"$in{tkt_id}",
			];
		my $response=$ua->request($reqs);
		if ($response->is_success) {
			$air_post_xml=$response->content;
			if ($air_post_xml=~/ET TICKET NUMBER IS NOT EXIST/ || $air_post_xml eq "N") {
				print &showMessage("错误提示", "您输入的票号不存在！", "goback", "", 2, "");
				&Footer();
				exit;
			}
		}else {
			my $responses=$response->status_line;
			print &showMessage("错误提示", "服务器连接失败,票号获取失败！", "goback", "", 2, "");
			&Footer();
			exit;
		}
	}
	$air_post_xml=~ s/\s*//g;
	if ($air_post_xml ne "") {
		my $XML_REMARK=@{&getXMLValue("REMARK",$air_post_xml)}[0];						#签注项(不得签转不得退票)
		my $XML_CON=@{&getXMLValue("CON",$air_post_xml)}[0];							#登机提醒(CZ378 H2乘机)
		my $XML_PNR=@{&getXMLValue("PNR",$air_post_xml)}[0];							#编码
		my $XML_BPNR=@{&getXMLValue("BPNR",$air_post_xml)}[0];							#编码
		my @XML_Names=split('\*',@{&getXMLValue("Names",$air_post_xml)}[0]);			#乘客姓名(按乘客*分割)
		my @XML_TAXTOTAL=split('\*',@{&getXMLValue("TAXTOTAL",$air_post_xml)}[0]);		#税(机场税+燃油税 合计)
		my @XML_Insure=split('\*',@{&getXMLValue("Insure",$air_post_xml)}[0]);			#CNY?(默认XXX 按乘客*分割)
		my @XML_Fares=split('\*',@{&getXMLValue("Fares",$air_post_xml)}[0]);			#票面价(按乘客*分割)
		my @XML_Taxs=split('\*',@{&getXMLValue("Taxs",$air_post_xml)}[0]);				#机场税合计(按乘客*分割)
		my @XML_Cards=split('\*',@{&getXMLValue("Cards",$air_post_xml)}[0]);			#证件号码(按乘客*分割)
		my @XML_Tkts=split('\*',@{&getXMLValue("Tkts",$air_post_xml)}[0]);				#票号(按乘客*分割)
		my @XML_YQs=split('\*',@{&getXMLValue("YQs",$air_post_xml)}[0]);				#燃油税合计(按乘客*分割)
		my @XML_Others=split('\*',@{&getXMLValue("Others",$air_post_xml)}[0]);			#其他费用合计(按乘客*分割)
		my @XML_Totals=split('\*',@{&getXMLValue("Totals",$air_post_xml)}[0]);			#票面+机场+燃油(按乘客*分割)
		my $XML_AIR=@{&getXMLValue("AIR",$air_post_xml)}[0];							#(出发城市名 航班号/航班日期/出发时间/舱位 抵达城市名 VOID)
		my $XML_res_id=@{&getXMLValue("res_id",$air_post_xml)}[0];						#订单号 or 票号
		my $XML_AIRTYPE=@{&getXMLValue("AIRTYPE",$air_post_xml)}[0];					#Y 国际机票
		$XML_AIRTYPE=($XML_AIRTYPE eq "Y")?"Y":"N";
		$XML_num=scalar(@XML_Names);#乘客人数
		$XML_airlinenum=0;		#航段数
		$Othersall=0;
		for ($i=0;$i<$XML_num ;$i++) {
			my $temp_Others=$XML_Others[$i];$temp_Others=~ s/CNY//g;$temp_Others=sprintf("%.2f",$temp_Others);
			$Othersall+=$temp_Others;
		}
		$Othersall=sprintf("%.2f",$Othersall);
		for ($i=1;$i>0 ;$i++) {
			my $line_C=@{&getXMLValue("$i\_C",$air_post_xml)}[0];		#出发城市 or 中转 or 抵达
			if ($line_C ne "" && $line_C ne "VOID") {
				my $departcd="";
				$sql="select IATA_ID from ctninfo..IATA_city where City_cname='$line_C' ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							$departcd=$row[0];
						}
					}
				}
				if ($departcd eq "") {
					print &showMessage("错误提示", "解析出错，航空城市 $line_C 系统无记录！", "goback", "", 2, "");
					&Footer();
					exit;
				}
				my $line_D=@{&getXMLValue("$i\_D",$air_post_xml)}[0];		#空
				my $line_A=@{&getXMLValue("$i\_A",$air_post_xml)}[0];		#航空公司简称
				my $line_F=@{&getXMLValue("$i\_F",$air_post_xml)}[0];		#航班号
				my $line_S=@{&getXMLValue("$i\_S",$air_post_xml)}[0];		#出发舱位
				my $line_DT=@{&getXMLValue("$i\_DT",$air_post_xml)}[0];		#出发日期
				my $line_T=@{&getXMLValue("$i\_T",$air_post_xml)}[0];		#出发时间
				my $line_L=@{&getXMLValue("$i\_L",$air_post_xml)}[0];		#舱位类型(Y100)
				my $line_SD=@{&getXMLValue("$i\_SD",$air_post_xml)}[0];		#未知时间段开始时间
				my $line_ED=@{&getXMLValue("$i\_ED",$air_post_xml)}[0];		#未知时间段结束时间
				my $line_B=@{&getXMLValue("$i\_ED",$air_post_xml)}[0];		#行李额(20K)
				my $line_Airline_ID=substr($line_F,0,2);#航空公司代码
				my $line_Flight_no=substr($line_F,2);#航班号
				if ($i>1) {
					my $XML_airlinenums=$XML_airlinenum-1;
					$C_Arrival[$XML_airlinenums]=$departcd;#抵达城市
				}
				if ($line_F eq "VOID") {
					$i=-1;
				}else{
					$C_Departure[$XML_airlinenum]=$departcd;#出发城市
					$C_code_name[$XML_airlinenum]=$line_A;#航空公司名称
					$C_Airline_ID[$XML_airlinenum]=$line_Airline_ID;#航空公司代码
					$C_Flight_no[$XML_airlinenum]=$line_Flight_no;#航班号
					$C_Seat_type[$XML_airlinenum]=$line_S;#舱位
					$C_Air_date[$XML_airlinenum]=$line_DT;#航班日期
					$C_Depart_time[$XML_airlinenum]=$line_T;#出发时间
					$XML_airlinenum++;
					
				}
			}else{
				$i=-1;
			}
		}
		if ($XML_airlinenum==0 || $XML_num<1) {
			print "<pre>$air_post_xml<br>XML_airlinenum:$XML_airlinenum<br>XML_num:$XML_num</pre>";
			print &showMessage("错误提示", "解析出错，请检查输入是否正确！", "goback", "", 2, "");
			&Footer();
			exit;
		}
		##=============================================================
		##验证查询sql
		$sql="select '','','','$XML_res_id',b.Corp_csname,b.Tel,
				b.Logo_gif,b.Homepage,'$XML_num','W','$XML_AIRTYPE',
				'$XML_PNR','','$Othersall',b.Corp_type,
				'','','','','','',
				b.Fax,b.Address,b.Corp_cname,'Y',,convert(char,getdate(),106)
			from ctninfo..Corp_info b
			where b.Corp_ID='$Corp_ID' ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$contact=$row[0];		$Usertel=$row[1];	$Usermb=$row[2];
					$in{resid} = $row[3];	$corp_name=$row[4];	$corp_tel=$row[5];
					$corp_logo=$row[6];		$homepage=$row[7];
					if ($Usertel eq $corp_tel) {	$Usertel = "";	}
					if ($Usermb eq $corp_tel) {	$Usermb = "";	}
					if ($Usermb eq $Usertel) {	$Usertel = "";	}
					if ($Usertel ne "")	{	$User_tel = $Usertel;	}
					if ($Usermb ne "")	{	$User_tel .= $Usermb;	}
					if ($User_tel eq "") {	$User_tel = "____________";		}
					$person_num=$row[8];	$bk_status=$row[9];
					$Is_inter=$row[10];		$pnr=$row[11];		$tkt_date=$row[12];
					$Total=int($row[13]);	$this_corptype = $row[14];
					$useraddress=$row[15];	$dev_time=$row[16];	$is_reward=$row[17];
					$book_user=$row[18];	$dev_user=$row[19];
					$comment=$row[20];		$corp_fax=$row[21];	$corp_addr=$row[22];
					$corp_fullname=$row[23];$Is_print=$row[24];
					## 从订单读取备注信息 jeftom @2011-3-8
					if ($in{cmt} ne 'Y') {
						$comment = '----';
					}
				}
			}
		}
		$Pat_rmk=$XML_REMARK;
		##=============================================================
		##Airbook查询sql
		$sqlbook="select '$XML_res_id' as Reservation_ID,'$pnr' as Booking_ref,getdate() as Ticket_time,'' as Office_ID,'N' as Pay_method,'$Corp_ID' as Agent_ID into #tempAirbook";
		##=============================================================
		##Airbook_lines查询sql
		$sqllines="";
		for (my $i=0;$i<$XML_airlinenum ;$i++) {
			if ($i==0) {
				$sqllines.="select '$C_Air_date[$i]' as Air_date,'$C_Airline_ID[$i]' as Airline_ID,'$C_Flight_no[$i]' as Flight_no,'$C_Depart_time[$i]' as Depart_time,'' as Arrive_time,'' as Equipment,'' as NumOfStops,'$C_Departure[$i]' as Departure,'$C_Arrival[$i]' as Arrival,'$XML_res_id' as Reservation_ID,$i as Res_serial,'' as IsReturn,'$C_Seat_type[$i]' as Seat_type,'' as Duration,'' as Arrive_date into #tempAirbooklines \n";
			}else{
				 $sqllines.="insert into #tempAirbooklines(Air_date,Airline_ID,Flight_no,Depart_time,Arrive_time,Equipment,NumOfStops,Departure,Arrival,Reservation_ID,Res_serial,IsReturn,Seat_type,Duration,Arrive_date) values('$C_Air_date[$i]','$C_Airline_ID[$i]','$C_Flight_no[$i]','$C_Depart_time[$i]','','','','$C_Departure[$i]','$C_Arrival[$i]','$XML_res_id','$i','','$C_Seat_type[$i]','','') \n";
			}
		}
		##=============================================================
		##Airbook_detail查询sql
		$sqldetail="";
		for (my $i=0;$i<$XML_airlinenum ;$i++) {
			for (my $j=0;$j<$XML_num ;$j++) {
				if ($i==0) {
					$XML_Fares[$j]=~ s/CNY//g;$XML_Fares[$j]=~ s/CN//g;$XML_Fares[$j]=sprintf("%.2f",$XML_Fares[$j]);
					$XML_Taxs[$j]=~ s/CNY//g;$XML_Taxs[$j]=~ s/CN//g;$XML_Taxs[$j]=sprintf("%.2f",$XML_Taxs[$j]);
					$XML_YQs[$j]=~ s/CNY//g;$XML_YQs[$j]=~ s/YQ//g;$XML_YQs[$j]=sprintf("%.2f",$XML_YQs[$j]);
				}else{
					$XML_Fares[$j]=0.00;$XML_Taxs[$j]=0.00;$XML_YQs[$j]=0.00;
				}
				my $Air_code=substr($XML_Tkts[$j],0,3);
				my $Ticket_ID=substr($XML_Tkts[$j],3);
				if ($i==0 && $j==0) {
					$sqldetail.="select '$XML_res_id' as Reservation_ID,$i as Res_serial,$j as Last_name,'$XML_Names[$j]' as First_name,'$XML_Cards[$j]' as Card_ID,$XML_Fares[$j] as Out_price,$XML_Taxs[$j] as Tax_fee,$XML_YQs[$j] as YQ_fee,'N' as Insure_type,0 as Insure_outprice,0 as Insure_num,0 as Other_fee,0 as Dept_ID,'$Air_code' as Air_code,'$Ticket_ID' as Ticket_ID,'' as Ticket_LID,'' as Insure_mode,'' as PY_name,0 as Origin_price,0 as In_price,'' as Seat_type into #tempAirbookdetail \n";
				}else{
					 $sqldetail.="insert into #tempAirbookdetail(Reservation_ID,Res_serial,Last_name,First_name,Card_ID,Out_price,Tax_fee,YQ_fee,Insure_type,Insure_outprice,Insure_num,Other_fee,Dept_ID,Air_code,Ticket_ID,Ticket_LID,Insure_mode,PY_name,Origin_price,In_price,Seat_type) values('$XML_res_id',$i,$j,'$XML_Names[$j]','$XML_Cards[$j]',$XML_Fares[$j],$XML_Taxs[$j],$XML_YQs[$j],'N',0,0,0,0,'$Air_code','$Ticket_ID','','','',0,0,'') \n";
				}
			}
		}
	}
}
if ($in{resid} eq "" && $air_post_xml eq "") {
	print &showMessage("错误提示", "您输入的订单号或订座记录编号无效！", "goback", "", 2, "");
	&Footer();
	exit;
}
if ($bk_status eq "C" && $air_post_xml eq "") {
	print &showMessage("错误提示", "不能对已取消订单创建行程单！", "goback", "", 2, "");
	&Footer();
	exit;
}
$sql="select a.Corp_ID,a.Logo_gif,b.Trip_logo,convert(char(10),getdate(),102)+''+convert(char(8),getdate(),108) from ctninfo..Corp_info a,ctninfo..Corp_extra b where a.Corp_ID=b.Corp_ID and a.Corp_ID='$Corp_center' ";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			if ($row[2] ne "") {
				$corp_logo="http://$G_WEBSITES/attach/$Corp_center/triplogo/$row[2]";
			}elsif($row[1] ne "" && $corp_logo eq ""){
				$corp_logo=$row[1];
			}
			$getdate=$row[3];
		}
	}
}
print qq`
<script type="text/javascript" src="/admin/js/popwin.js"></script>
<div id="append_parent"></div>
<script language="javascript">
	var wayshow={};wayshow.seek="no";wayshow.folder="no";wayshow.look="litimg";wayshow.order="mtime";wayshow.ordermm="desc";wayshow.img="off";wayshow.Type="triplogo";
	function OnUploadCompleted(errorNumber, fileUrl, fileName, customMsg){
		document.getElementById("corp_logo").src=fileUrl;
		pmwin('close');
	}
</script>
<input type="hidden" name="URL" id="URL" value="http://$G_WEBSITES/attach/$Corp_center/triplogo/"/>
<script type="text/javascript">
function printInv(){
	if ("$Is_print"!="Y") {
		\$.getJSON("/cgishell/golden/admin/manage/get_ffp.pl?callback=?", {User_ID:"$in{User_ID}",Serial_no:"$in{Serial_no}",Form_type:"air_trip",resid:"$in{resid}"},
		function(data) {
			var Isreturn=data['air_trip'];//0:订单号为空;1:无此订单;2:该订单已标记打印;3:打印标记成功;4:打印标记失败
			printInv1();
		});
	}else{
		printInv1();
	}
}
function printInv1(){
	var marginTop = document.getElementById("layerbox").style.pixelTop;
	var marginLeft = document.getElementById("layerbox").style.pixelLeft;
	setcookie('marginTop', marginTop, 864000, '', '', '');
	setcookie('marginLeft', marginLeft, 864000, '', '', '');
	
	if(Fid('tab_content_1')) setcookie('tab_content_1', Fid('tab_content_1').style.fontSize, 864000, '', '', '');
	if(Fid('tab_content_2')) setcookie('tab_content_2', Fid('tab_content_2').style.fontSize, 864000, '', '', '');
	if(Fid('tab_content_3')) setcookie('tab_content_3', Fid('tab_content_3').style.fontSize, 864000, '', '', '');
	if(Fid('tab_content_4')) setcookie('tab_content_4', Fid('tab_content_4').style.fontSize, 864000, '', '', '');
	if(Fid('tab_content_5')) setcookie('tab_content_5', Fid('tab_content_5').style.fontSize, 864000, '', '', '');
	if(Fid('tab_content_6')) setcookie('tab_content_6', Fid('tab_content_6').style.fontSize, 864000, '', '', '');
	window.print();
}

//键盘操作部分
function showmargin() {
	document.getElementById("showmargin").innerHTML = "左边距：" + document.getElementById("layerbox").style.pixelLeft + " px<br>上边距：" + document.getElementById("layerbox").style.pixelTop + " px";
}

var timer,X,Y;
function moveItem(x,y) {
	document.getElementById("layerbox").style.pixelTop += y;
	document.getElementById("layerbox").style.pixelLeft += x;
	showmargin();
}
// 键盘事件： 上38 / 下40 / 左37 / 右39
function ctrlMove() {
	switch(event.keyCode)
	{
		case 37:
			moveItem(-1,0);
			break;
		case 38:
			moveItem(0,-1);
			break;
		case 39:
			moveItem(1,0);
			break;
		case 40:
			moveItem(0,1);
			break;
	}
}
var curfontsize, curlineheight;
function init() {		
	var marginTop = getcookie('marginTop');
	var marginLeft = getcookie('marginLeft');
	if ( $in{trip} == "7"){
		curfontsize = getcookie('curfontsize');
		curlineheight = getcookie('curlineheight');
		if (curfontsize) {
			document.getElementById("caption2").style.fontSize = curfontsize+'px';
		}
		if (curlineheight) {
			document.getElementById("caption2").style.lineHeight = curlineheight+'px';
		}
	}
    
	if (marginTop) {
		document.getElementById("layerbox").style.pixelTop = marginTop;
	}
	if (marginLeft) {
		document.getElementById("layerbox").style.pixelLeft = marginLeft;
	}
	showmargin();
	for (var i = 1; i < 7; i++) {
		try {
			Fid('tab_content_' + i).style.fontSize = getcookie('tab_content_' + i);
		}
		catch(e){};
	}
}

// 插入输入对象
function insertText(e, type) {
	$insertText
	var parentObj = e.parentNode;
	var objText = e.innerHTML;
	objText = objText.replace(/<br>/gi, "\\n");
	var objId = e.id + type;
	var sObj = document.getElementById(objId);
	if (type == 1)
	{
		e.style.display = 'none';
		if (!sObj)
		{
			var element = document.createElement('input');
			element.className = 'group';
			element.id = objId;
			element.value = objText;
			element.title = '输入完成按回车键';
			element.onblur = function () { setValue.call(this, e); };
			element.onkeypress = function () { if(event.keyCode==13) { setValue.call(this, e); } };
			parentObj.appendChild(element);
			document.getElementById(objId).select();
		}
		else {
			sObj.style.display = '';
			sObj.value = objText;
			sObj.title = '输入完成按回车键';
			sObj.select();
			sObj.onblur = function () { setValue.call(this, e); };
			sObj.onkeypress = function () { if(event.keyCode==13) { setValue.call(this, e); } };
		}
	}
	else if (type == 2)
	{
		e.style.display = 'none';
		if (!sObj) {
			var element = document.createElement('textarea');
			element.className = 'grouparea';
			element.id = objId;
			var elementText = document.createTextNode(objText);
			element.onblur = function () { setValue.call(this, e); };
			element.appendChild(elementText);
			parentObj.appendChild(element);
			document.getElementById(objId).select();
		}
		else {
			sObj.style.display = '';
			sObj.value = objText;
			sObj.select();
			sObj.onblur = function () { setValue.call(this, e); };
		}
	}
}
// 设置为输入的文本
function setValue(e) {
	var v = this.value;
	v = v.replace(/\\n/g, "<br>");
	e.style.display = '';
	e.innerHTML = v;
	this.style.display = 'none';
}


// 隐藏元素
function closeItem (e) {
	var item = document.getElementById(e);
	item.style.display = 'none';
}

curfontsize = curfontsize ? curfontsize : 14;
curlineheight = curlineheight ? curlineheight : 16;
function fontZoom(option, obj){
	if (obj.style.fontSize == '') {
		curfontsize = 14;
		curlineheight = 16;
	}
	if (option == 'down') {
		if(curfontsize > 8){
			obj.style.fontSize = (--curfontsize) + 'px';
			obj.style.lineHeight = (--curlineheight) + 'px';
		}
	}
	else if (option == 'up') {
		if(curfontsize < 18){
			obj.style.fontSize = (++curfontsize) + 'px';
			obj.style.lineHeight = (++curlineheight) + 'px';
		}
	}
	else {
		obj.style.fontSize = '';
		obj.style.lineHeight = '';	
	}
	var timer=null;		
	if ( $in{trip} == "7"){
		clearTimeout(timer);
		timer=setTimeout(function(){		// 函数节流
			setcookie('curfontsize', curfontsize, 864000, '', '', '');
			setcookie('curlineheight', curlineheight, 864000, '', '', '');
		},1000);
	}
}

</script>`;
if ($in{resid} ne "") {
	$sql =" select Remark from ophis..Op_rmk where Res_ID='$in{resid}' and Sales_ID='$Corp_center' and Op_type='12' order by Op_time ";
	$db->ct_execute($sql);	
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT) {
			while(@row = $db->ct_fetch) {
				$Pat_rmk .= $row[0];
			}
		}
	}
}
if ($Pat_rmk eq "" || $Pat_rmk eq " ") {
	$Pat_rmk="不能改签、不能更改路线";
}
## ------------------------------------------------------------------------
if ($in{relate_num} eq "") {	## 关联订单处理
	$in{relate_num} = 0;
	if ($in{resid} ne "") {
		## 查询此订单是否有关联订单	 dabin@2009-07-31
		$sql = "select rtrim(Relate_ID) from ctninfo..Res_relate where Res_ID=(select Res_ID from ctninfo..Res_relate where Relate_ID='$in{resid}') ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					if ($row[0] ne $in{resid}) {	push(@resid,$row[0]);	$in{relate_num}++;	}
				}
			}
		}
	}
}
else{	## 处理选中的关联订单信息
	for (my $i=0;$i<$in{relate_num};$i++) {
		my $ck="ck_$i";
		if ($in{$ck} ne "") {	
			if ($s_resid ne "") {	$s_resid .= "','";		}
			$s_resid .= $in{$ck};
		}
	}
}

## ------------------------------------------------------------------------
if ($in{print_logo} eq "Y") {	## add by jeftom 2008-7-23  不显示公司标志
	if ($in{trip} eq '5') {
		$corp_logo = qq`<img src='$corp_logo' id='corp_logo'/>`;
	}else{
		$corp_logo = qq`<img src='$corp_logo' id='corp_logo' onclick="javascript:pmwin('open','http://$G_WEBSITES/cgishell/golden/admin/message/attach_govern.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&module=content','选择行程单logo',750,350);"/>`;
	}
} else {
	$corp_logo = "<div style='width: 230px;'></div>";
}
## 签约公司/差旅客户 显示中心的信息 add by jeftom @ 2009-3-10
if ($this_corptype eq 'B') {
	$sql = "SELECT Corp_csname, Tel, Custom_line FROM ctninfo..Corp_info WHERE Corp_ID='$Corp_center'";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$corp_name = $row[0];
				$corp_tel = $row[1];
				if ($row[2] ne '') {
					$corp_tel = $row[2];
				}
			}
		}
	}
}
if (($Alert_status eq "1" || $Alert_status eq "2")&&$in{trip} eq "") { #退废单默认退票页面 hejc@2017-07-19 
	$in{trip}="7";
}

if ($Is_inter eq "Y" && $in{trip} ne '3' && $in{trip} ne '7' ) {
	if ($in{trip} ne '4') {
		$in{trip} = 1;
	}
}
## ---------------------------------------------------------------------
## 查询航段及乘客信息
## ---------------------------------------------------------------------
$air_num = 0;
$sql = qq!select distinct datepart(dw,a.Air_date),d.Airline_cname,d.Airline_name,rtrim(a.Airline_ID + a.Flight_no),
	convert(char(10),a.Air_date,102),b.City_cname,b.City_name,c.City_cname,c.City_name,a.Depart_time,a.Arrive_time,
	d.Airline_logo,rtrim(a.Equipment),a.NumOfStops,e.Seat_type,a.Departure,a.Arrival,datediff(day,getdate(),a.Air_date),
	b.Airport_cname,c.Airport_cname,b.Time_diff,c.Time_diff,a.Reservation_ID,a.Res_serial,a.IsReturn,a.Arrive_date
	FROM ctninfo..Airbook_lines_$Top_corp a, 
		ctninfo..IATA_city b,
		ctninfo..IATA_city c,
		ctninfo..Airlines d,
		ctninfo..Airbook_detail_$Top_corp e
	WHERE a.Reservation_ID = e.Reservation_ID
		and a.Res_serial = e.Res_serial
		and a.Airline_ID = d.Airline_code 
		and a.Departure = b.IATA_ID 
		and a.Arrival = c.IATA_ID \n!;	
if ($s_resid ne "") {
	$sql .= qq!and a.Reservation_ID in ('$in{resid}','$s_resid')
		order by a.Reservation_ID,a.Res_serial !;
}
else{
$sql .= qq!and a.Reservation_ID = '$in{resid}'
	order by a.Res_serial !;
}
if ($sqllines ne "") {
	$sql="$sqllines
		select distinct datepart(dw,a.Air_date),d.Airline_cname,d.Airline_name,rtrim(a.Airline_ID + a.Flight_no),
			convert(char(10),a.Air_date,102),b.City_cname,b.City_name,c.City_cname,c.City_name,a.Depart_time,a.Arrive_time,
			d.Airline_logo,rtrim(a.Equipment),a.NumOfStops,a.Seat_type,a.Departure,a.Arrival,datediff(day,getdate(),a.Air_date),
			b.Airport_cname,c.Airport_cname,b.Time_diff,c.Time_diff,a.Reservation_ID,a.Res_serial,a.IsReturn,a.Arrive_date
		FROM #tempAirbooklines a, 
			ctninfo..IATA_city b,
			ctninfo..IATA_city c,
			ctninfo..Airlines d
		WHERE a.Airline_ID = d.Airline_code 
			and a.Departure = b.IATA_ID 
			and a.Arrival = c.IATA_ID 
		order by a.Res_serial
		drop table #tempAirbooklines ";
}
#print "<pre>$sql";

my @departcity = ();
my @arrivecity = ();
my @departdate = ();
my @departtime = ();
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT) {
		while(@row = $db->ct_fetch) {
			my $d_week=$Day_name[$row[0]-2];	push(@a_week,$d_week);					push(@depart_date,$row[4]);
			my $airname = $row[1];		if ($airname eq "")	{	$airname = $row[2];	}	push(@a_name,$airname);
			
			my $s_city = $row[5];		if ($s_city eq "")	{	$s_city = $row[6];	}

			push(@departcity, $s_city);
			push(@departdate, &convertdate($row[4]));

			if ($Is_inter eq "Y" && $in{trip} ne '4') {		
				$row[18] =~ s/\s*国际机场//g;		$row[18] =~ s/\s*机场//g;	$row[18] =~ s/\s*//g;	
				if ($row[18] ne "") {	$s_city .= "<br>($row[18])";	}
			}
			else{	$s_city .= $row[18];	}
			push(@a_depart,$s_city);	$row[6] =~ tr/a-z/A-Z/;		push(@a_depart_e,$row[6]);
			
			my $e_city = $row[7];		if ($e_city eq "")	{	$e_city = $row[8];	}

			push(@arrivecity, $e_city);	## 发送行程单邮件

			if ($Is_inter eq "Y" && $in{trip} ne '4') {		
				$row[19] =~ s/\s*国际机场//g;		$row[19] =~ s/\s*机场//g;	$row[19] =~ s/\s*//g;	
				if ($row[19] ne "") {	$e_city .= "<br>($row[19])";	}
			}
			else{	$e_city .= $row[19];	}
			push(@a_arrive,$e_city);	$row[8] =~ tr/a-z/A-Z/;		push(@a_arrive_e,$row[8]);
			push(@air_port, $row[24]);	## 航班停靠航站楼
			
			my $day = substr($row[4],0,4)."年".substr($row[4],5,2)."月".substr($row[4],8,2)."日"; push(@a_date,$day);
			my $t_hour = substr($row[10],0,2) - substr($row[9],0,2);	# 飞行时间(时)=抵达时间-起飞时间
			my $arrive_date = $row[4];	# 抵达日期
	
			if ($row[25]=~/-(\d)$/) {##1630-1 昨天的    liangby@2014-9-16 
			  
				my $pre_daynum=$1;
				while($pre_daynum>0){
					$arrive_date=&Prevdate($arrive_date);
					$pre_daynum--;
				}
			}
			## 国际机票计算时差 jeftom @2009-3-10
			## 算法：飞行时间(时)=降落地减去与北京时间时差 - 起飞地减去与北京时间时差
			if ($in{trip} == 1 || $in{trip} == 4) {
				$t_hour = (substr($row[10],0,2) - $row[21]) - (substr($row[9],0,2) - $row[20]);
			}

			if ($t_hour < 0) {	$t_hour = 24 + $t_hour;		}
			if ($t_hour < 0) {	$t_hour = 24 + $t_hour;	$arrive_date = &Nextdate($arrive_date);		}
			#print "$t_hour<br>";
			my $t_min = substr($row[10],2,2) - substr($row[9],2,2);
			if ($t_min < 0) {	$t_hour --;		$t_min = 60 + $t_min;	}
			if ($t_hour < 10 && $t_hour > 0) {	$t_hour = "0".$t_hour;	}
			if ($t_min < 10) {	$t_min = "0".$t_min;	}
			my $times = $t_hour."小时".$t_min."分";
			if ($in{trip} == 1 || $in{trip} == 4) {	$times = "$t_hour:$t_min";	}	push(@a_dur,$times);
			#print $times, "<br>";
			
			##　计算抵达日期，默认为起飞日期。 jeftom @2009-10-22
			my $d_hour = substr($row[9],0,2);	# 起飞时间(时)
			my $d_minute = substr($row[9],2,2);	# 起飞时间(分)
			if ($d_minute + $t_min > 59) {
				$d_hour++;
			}
			## 起飞时间(时)-时差+飞行时间(时)>23 为第二天 jeftom @2009-12-03
			my $timediff = $row[20] - $row[21];
			#if ($timediff > 0) {
				#$timediff = -$timediff;
			#}
			
			if (($d_hour - $timediff) + $t_hour > 23) {
				$arrive_date = &Nextdate($arrive_date);
			}
			
			push(@arrive_date, $arrive_date);	# 抵达日期
			push(@a_flight,$row[3]);			# 航班号
			push(@departtime, $row[9]);			## 发送行程单邮件
			$row[9]=substr($row[9],0,2).":".substr($row[9],2,2);	push(@a_dtime,$row[9]);	
			$row[10]=substr($row[10],0,2).":".substr($row[10],2,2);	push(@a_atime,$row[10]);
			
			push(@a_logo,$row[11]);		push(@a_equip,$row[12]);	
			if ($row[13] eq "1") {	$row[13]=" 【<b>经停</b>】";		}	else{	$row[13]="";	}
			push(@a_stop,$row[13]);		push(@a_class,$row[14]);
			push(@a_dcity,$row[15]);	push(@a_acity,$row[16]);	push(@d_add,$row[17]);
			push(@a_resid,$row[22]);	push(@a_serial,$row[23]);
			$air_num ++;
		}
	}
}

## ====================================
## 获取城市列表 jeftom @2010-01-20
## ====================================
my @cityname = ();
my %hash_tmpcity;
push(@cityname, @a_dcity);
push(@cityname, @a_acity);
@cityname = grep(!$hash_tmpcity{$_}++, @cityname);
my $cityname = join("','", @cityname);
my %cityname = ();

$sql = "SELECT IATA_ID, City_cname FROM ctninfo..IATA_city WHERE IATA_ID IN ('$cityname')";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			$cityname{$row[0]} = $row[1];
		}
	}
}
## 定义航空公司
my %AIRLINESSNAME=();#fanzy@2012-10-29
$sql = "SELECT Airline_code,Airline_csname FROM ctninfo..Airlines where Airline_type='1' and Airline_csname+''<>'' ";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			$AIRLINESSNAME{$row[0]} = $row[1];
		}
	}
}

## ====================================
## 获取当前页面地址参数 jeftom @2010-01-20
## ====================================
my $forward = "?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}";
foreach my $capword (sort keys(%in)) {
	if ($capword ne 'User_ID' && $capword ne 'Serial_no' && $capword ne 'trip') {
		$forward .= "&$capword=$in{$capword}";
	}
}
if ($in{resid} ne "") {
	## 获取出票人姓名
	$sql = "select a.User_name from ctninfo..User_info_op a,ctninfo..Airbook_$Top_corp b
		WHERE a.User_ID = b.Ticket_by and b.Reservation_ID='$in{resid}' and a.User_type in ('O','S') ";	
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$ticketuser=$row[0];	
			}
		}
	}
}

if ($in{resid} ne "") {
	## 获取订座人姓名
	$sql = "select a.User_name from ctninfo..User_info_op a,ctninfo..Airbook_$Top_corp b
		WHERE a.User_ID = b.Book_ID and b.Reservation_ID='$in{resid}' and a.User_type in ('O','S') ";	
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$book_name=$row[0];	
			}
		}
	}
}

## 获取送票员姓名
$sql = "SELECT User_name FROM ctninfo..User_info_op WHERE Corp_num='$Corp_center' AND User_ID='$dev_user'";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			$deliveryuser = $row[0];	
		}
	}
}


## 获取积分信息
my $userid = '';
$sql = "SELECT Total_reward,Pay_reward,Is_sendcard FROM ctninfo..User_info WHERE Corp_num='$Corp_center' AND User_type='C' AND User_ID='$book_user' ";
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			$total_reward = $row[0];
			$pay_reward = $row[1];
			$userid = $book_user;
		}
	}
}

my $cust_name = '', $cust_fullname = '', $cust_tel = '';
if ($userid ne '') {
	$sql = "SELECT a.Corp_csname, a.Corp_cname, a.Tel FROM ctninfo..Corp_info AS a, ctninfo..User_info as b 
				WHERE a.Corp_num='$Corp_center' AND b.Corp_num='$Corp_center' AND a.Corp_num=b.Corp_num
					AND a.Corp_ID=b.Corp_ID AND b.User_type='C' AND b.User_ID='$book_user' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$cust_name = $row[0];
				$cust_fullname = $row[1];
				$cust_tel = $row[2];
			}
		}
	}
}

my %idcard_type = (
	'DD' => '台胞证',
	'ID' => '军官证',
	'NI' => '身份证',
	'OD' => '其它',
	'PP' => '护照',
	'SD' => '士兵证',
);

## ====================================
## 国际航站楼
## ====================================
#my %depart_points = ();
#$depart_points{PEK}{LON}{CA} = '3号航站楼';
#$depart_points{PEK}{LON}{MU} = '4号航站楼';
#$depart_points{PEK}{FRA}{CA} = '1号航站楼';
#$depart_points{PEK}{FRA}{MU} = '2号航站楼';
#$depart_points{PEK}{CDG}{CA} = '1号航站楼';
#$depart_points{PEK}{CDG}{MU} = '2F航站楼';
#$depart_points{PEK}{LAX}{CA} = '3号航站楼';
#$depart_points{PEK}{LAX}{MU} = '4号航站楼';
#$depart_points{PEK}{NYC}{CA} = '1号航站楼';
#$depart_points{PEK}{NYC}{MU} = '1号航站楼';
#$depart_points{PEK}{SYD}{MU} = '1号航站楼';
#$depart_points{PEK}{MEL}{CA} = '2号航站楼';
#$depart_points{PEK}{MEL}{MU} = '2号航站楼';
#$depart_points{PEK}{MUC}{CA} = '2号航站楼';
#$depart_points{PEK}{ROM}{CA} = 'C航站楼';
#$depart_points{PEK}{STO}{CA} = '5号航站楼';
#$depart_points{PEK}{SAO}{CA} = '1号航站楼';
#$depart_points{PEK}{MIL}{CA} = '1号航站楼';
#$depart_points{PEK}{MAD}{CA} = '1号航站楼';
#if ($Corp_center eq "CZZ259") {##灿烂阳光的不显示，航站楼以航信给客人的A4为准，其他客户有同样需求的，可统一屏蔽   lianby@2014-4-30
	#%depart_points = ();
#}

## ====================================
## 行程单模板 jeftom @2009-09-11
## ====================================
$sql = "SELECT rtrim(Msg), Msg_type, Msg_serial FROM ctninfo..City_msg WHERE Corp_ID='$template_corp' AND Msg_type IN('T', 'H')";
my $template = qq`尊敬的 <b>{username}</b> 您好！\r\n您的行程单：<b>{resid}</b>。<b>{corpname}</b> 预祝您旅途愉快！建议您仔细阅读退改签规定并于出发前与航空公司确认航班有无变更。我们也会在收到航班变更信息后及时通知您。如您需要 <b>预订酒店或其它服务</b> 请致电客服热线：{corptele}`;
my $templatebody = '';
$db->ct_execute($sql);
while($db->ct_results($restype) == CS_SUCCEED) {
	if($restype==CS_ROW_RESULT)	{
		while(@row = $db->ct_fetch)	{
			if ($row[0] ne '' && $row[1] eq 'T') {
				$template = $row[0];
			}
			elsif ($row[1] eq 'H' && $row[2] eq $in{templateid}) {
				$templatebody = &get_template($template_corp . '_' . $in{templateid} . '.html');
			}
		}
	}
}

##==================================================
my $usertel = $Usertel ne '' ? $Usertel : $Usermb;
$templatebody =~ s/{username}/$contact/g;	## 用户名称
$templatebody =~ s/{userid}/$userid/g;	## 会员号
$templatebody =~ s/{resid}/$in{resid}/g;	## 订单号
$templatebody =~ s/{totalreward}/$total_reward/g;	## 累积积分
$templatebody =~ s/{payreward}/$pay_reward/g;	## 已兑换积分
$templatebody =~ s/{bookuser}/$book_name/g;	## 订座员
$templatebody =~ s/{ticketuser}/$ticketuser/g;	## 出票员
$templatebody =~ s/{deliveryuser}/$deliveryuser/g;	## 送票员
$templatebody =~ s/{usertel}/$usertel/g;	## 联系电话
$templatebody =~ s/{useraddress}/$useraddress/g;	## 配送地址
$templatebody =~ s/{deliverytime}/$dev_time/g;	## 送达时间

$templatebody =~ s/{corpfullname}/$corp_fullname/g;	## 公司全称
$templatebody =~ s/{corpname}/$corp_name/g;	## 公司名称
$templatebody =~ s/{corptele}/$corp_tel/g;	## 客服热线
$templatebody =~ s/{corpfax}/$corp_fax/g;	## 传真
$templatebody =~ s/{corpaddr}/$corp_addr/g;	## 公司地址

$templatebody =~ s/{custname}/$cust_name/g;	## 客户名称(简)
$templatebody =~ s/{custfullname}/$cust_fullname/g;	## 客户名称(全)
$templatebody =~ s/{custtel}/$cust_tel/g;	## 客户电话号码
$templatebody =~ s/{pnr}/$pnr/g;	## 订座记录
$templatebody =~ s/{logo}/$corp_logo/g;	## 中心公司LOGO

my ($templateheader, $templatefooter) = split('{pagebody}', $templatebody);

$template =~ s/\r\n/<br>/g;
$template =~ s/{username}/$contact/g;	## 用户名称
$template =~ s/{resid}/$in{resid}/g;	## 订单号
$template =~ s/{corpname}/$corp_name/g;	## 公司名称
$template =~ s/{corptele}/$corp_tel/g;	## 客服热线


## ---------------------------------------------------------------------
## 国际行程单模板，易登机用	 dabin@2009-2-23         
if ($in{trip} == 1 || $in{trip} == 4) {
	my $html_personinfo = '';
	my $ii = 0;
	my @Personinfo = ();
	$sql = "select a.First_name,rtrim(a.Card_ID),a.Out_price+a.Other_fee,a.Tax_fee+a.YQ_fee,a.YQ_fee,a.Insure_type,
				a.Insure_outprice,a.Insure_num,a.Other_fee,'',a.Dept_ID,
				a.Air_code,a.Ticket_ID,a.Ticket_LID,a.Insure_mode, a.PY_name,
				a.Refund_cause,a.Expiry_date,a.Origin_price	--18
			from ctninfo..Airbook_detail_$Top_corp a
			where a.Reservation_ID = '$in{resid}'
				and a.Res_serial=0
			order by a.Res_serial,a.Last_name,a.Ticket_ID" ;
	if ($sqldetail ne "") {
	$sql = "$sqldetail
			select a.First_name,rtrim(a.Card_ID),a.Out_price+a.Other_fee,a.Tax_fee+a.YQ_fee,a.YQ_fee,a.Insure_type,
				a.Insure_outprice,a.Insure_num,a.Other_fee,'',a.Dept_ID,
				a.Air_code,a.Ticket_ID,a.Ticket_LID,a.Insure_mode, a.PY_name,
				a.Refund_cause,a.Expiry_date,a.Origin_price	--18
			from #tempAirbookdetail a
			where  a.Res_serial=0
			order by a.Res_serial,a.Last_name,a.Ticket_ID
			drop table #tempAirbookdetail " ;
	}
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT) {
			while(@row = $db->ct_fetch) {
				push(@Personinfo,$row[0]);
				if($Is_inter eq "Y" && $center_airparm =~/q/){
					$price_total+=$row[18];
				}else{
					$price_total+=$row[2];
				}
				$tax_total+=$row[3];
				my $tk_id = "";
				if ($row[12] > 0) {
					$tk_id = "$row[11]-$row[12]";
					if ($row[13] > 0) {	$tk_id.="-$row[13]";	}
				}
				if ($row[1] eq '') {
					$row[1] = '__';
				}

				## 提取 姓名，生日，护照有效期 jeftom @2011-3-21
				my $gender = $row[14] eq 'M' ? '男' : '女';
				my @ttb = split('/', $row[15]);
				#my ($birth, $pp_expire) = split('-', $ttb[0]);
				my ($birth, $pp_expire) = ($row[16], $row[17]);
				$birth =~ s/\s*//;
				$pp_expire =~ s/\s*//;
				if ($birth eq '') {
					$birth = '__';
				}
				if ($pp_expire eq '') {
					$pp_expire = '__';
				}
				if ($tk_id eq '') {
					$tk_id = '__';
				}
				my $cardtype_pre = substr($row[1], 0, 2);
				my $insure_num="";
				if ($row[5] eq 'Y') {## 购买保险 hecc@2013-8-16
					$insure_num="+";
				}else {## 赠送保险
					$insure_num="-";
				}
				if ($row[7] ne '0') {
					$insure_num.=$row[7];
				}else{
					$insure_num="";
				}
				if ($in{trip} == 4) {
					$html_personinfo .= qq`
					<tr>
						<td><em id="passengername_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[0] $insure_num</em></td>
						<td><em id="passporttype_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$idcard_type{$cardtype_pre}</em></td>
						<td><em id="passport_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[1]</em></td>
						<td><em id="ticketnumber_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$tk_id</em></td>
					</tr>`;
				}
				else {##字体加大需调整了一下排版 chengzx@2013-8-23
					$html_personinfo .= qq`
					<tr>
						<td width="33%"><strong>旅客姓名(NAME)：</strong><em id="passengername_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[0] $insure_num</em></td>
						<td width="33%"><strong>票号(ETKT NBR)：</strong><em id="ticketnumber_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$tk_id</em></td>
					</tr>
					<tr>
							<td><strong><nobr>护照号(PASSPORT NO.)：<nobr></strong><em id="passportnum_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[1]</em></td>
							<td><strong>护照有效期(DATE OF EXPIRY)：</strong><em id="passport_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$pp_expire</em></td>
					</tr>
					<tr>
						<td width="33%"><strong>性别(SEX)：</strong><em id="gender_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$gender</em></td>
						<td width="33%"><strong>出生日期(BIRTHDAY)：</strong><em id="borthday_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$birth</em></td>
					
					</tr>`;
				}
				$ii++;
			}
		}
	}
	$ii = 0;

	##通过RTC获取行李数量  wfc@2013-07-01
	my $Person_diff=0;#判断行李是否按乘客计算 0按航段,1按乘客
	my $bag_tmp="";
	if (length($pnr)==6) {
		## 获取代理人的民航配置信息
		&get_tcp_parm();			
		## 起动连接，访问航空服务器
		&tcp_connect($Server_ip,$Server_port);	
		$BUFFER = $in{User_ID}."*RTC/$pnr#ALL#";
		$BUF=&get_tcp_air($BUFFER);		## 执行指令	
		shutdown(S, 2);					## 关闭连接
		##查找行李信息 wfc@2013-07-01
		#016/016 FC/A/01AUG13PUS A-01AUG14 F-1PC KE X/SEL 65.74YKE A-01FEB14 KE TSN     -
		#		 Q38.00 187.33HHEKC KE X/SEL Q38.00 187.33HHEKC A-01AUG14 KE PUS
		#		 65.74YKE NUC582.14END ROE1120.972000/LEE/YOUNGKYUNG
		if (length($BUF)>50) {
			my $find=$s_pos=$e_pos=0;
			my $next_find="Y";
			$find = index($BUF,"FC/A/");
			if ($find>0) {
				while ($next_find eq "Y") {
					my $pnr_info;
					$s_pos = index($BUF,"FC/A/",$e_pos);
					$e_pos = index($BUF,"FC/A/",$s_pos+5);
					if ($e_pos>=0) {
						$pnr_info = substr($BUF,$s_pos,$e_pos-$s_pos);
					}
					else{
						$pnr_info = substr($BUF,$s_pos,length($BUF)-$s_pos);
						$next_find="N";
					}
					for (my $j=0;$j<$air_num ;$j++) {
						my $airline = substr($a_flight[$i], 0, 2);
						if (index($pnr_info,"F-")>=0 && index($pnr_info,$airline)>=0) {
							my $s_str = index($pnr_info,"F-");
							my $e_str = index($pnr_info,$airline);
							my $bag = substr($pnr_info,$s_str+2,$e_str-$s_str-2);
							if ($bag_tmp ne "") {
								if ($bag_tmp ne $bag) {##判断是否所有乘客都一样
									$Person_diff = 1;
								}
							}
							$bag_tmp = $bag;
							$bag =~ s/PC/件(PC)/;
							$$airline{bag} = $bag;
							for (my $k=0;$k<scalar(@Personinfo) ;$k++) {
								if (index($pnr_info,$Personinfo[$k])>=0) {##判断是否按乘客计算
									$$Personinfo[$k]{$airline} = $bag;
									last;
								}
							}
						}
					}
				}
			}
		}
	}

	my $html_scheduling = '';
	for ($i=0; $i<$air_num; $i++) {
		my $scheduling_num = $i + 1;
		my $flight_airlines = substr($a_flight[$i], 0, 2);
		my $bag = "20KG";
		if ($a_class[$i] eq "C" || $a_class[$i] eq "D" || $a_class[$i] eq "Z" || $a_class[$i] eq "I" || $a_class[$i] eq "J") {	## 国际票公务舱
			$bag = "30KG";
		}
		elsif ($a_class[$i] eq "F" || $a_class[$i] eq "A") {	## 国际票头等舱
			$bag = "40KG";
		}

		##匹配PNR里面的行李信息 wfc@2013-07-01
		if ($Person_diff eq "0" && $$flight_airlines{bag} ne "") {##航段
			$bag = $$flight_airlines{bag};
		}
		elsif ($Person_diff eq "1") {##乘客
			$bag = "";
			for (my $j=0;$j<scalar(@Personinfo) ;$j++) {
				$bag .="$Personinfo[$j] $$Personinfo[$j]{$flight_airlines},   ";
			}
		}

		my %weather = ();
		my $w_date = substr($a_date[$i],6,2).substr($a_date[$i],10,2);
		## 出发城市
		my $s_date = $t_date;	my $d_name=$today;
		if ($d_add[$i] >=0 && $d_add[$i] < 3) {	$s_date = $w_date;	$d_name=$a_date[$i];	}	## 最近三天
		my $find = 0;
		for ($j=0;$j<scalar(@dis_date);$j++) {
			if ($dis_date[$j] eq $s_date && $dis_city[$j] eq $a_dcity[$i]) {	## 相同城市，不再显示
				$find = 1;
			}
		}
		if ($find == 0) {
			push(@dis_date,$s_date);	push(@dis_city,$a_dcity[$i]);
			$sql = "select City_ID,Min_tmp,Max_tmp,Weather,Cloud from ctninfo..Weather where City_ID in('$a_dcity[$i]','$a_acity[$i]') and W_date='$s_date' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT) {
					while(@row = $db->ct_fetch) {
						$weather{$row[0]} = qq`$row[1]－$row[2]℃ $row[3] $row[4]`;
						$find ++;	
					}
				}
			}
		}

		if ($in{trip} == 4) {
			if ($a_dur[$i] =~ m/:/) {
				$a_dur[$i] = substr($a_dur[$i], 0, 2) . '小时' . substr($a_dur[$i], 3, 2) . '分';
			}
			if ($weather{$a_dcity[$i]} eq '') {
				$weather{$a_dcity[$i]} = '__';
			}
			if ($weather{$a_acity[$i]} eq '') {
				$weather{$a_acity[$i]} = '__';
			}
			if ($a_stop[$i] eq '') {
				$a_stop[$i] = '__';
			}
			my $order_status = &cv_airstatus($bk_status,"S",0);
			##显示航站楼 hecf 2014/8/15
			my($dport0,$aport0)=('','');
			if ($Corp_center ne "CZZ259") {##灿烂阳光的不显示，航站楼以航信给客人的A4为准，其他客户有同样需求的，可统一屏蔽   hecf@2014-8-18
				$dport0 =~ s/^\s+|\s+$//g;
				$aport0 =~ s/^\s+|\s+$//g;
				if($dport0 ne ""){$dport0="$dport0号航站楼";}
				if($aport0 ne ""){$aport0="$aport0号航站楼";}
			}
			
			$html_scheduling .= qq`
					<tr class="thead"><th colspan="4">第 $scheduling_num 段 普通航段</th></tr>
					<tr>
						<th>日期：</th>
						<td><em id="adepartdate_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$depart_date[$i] ($a_week[$i])</em></td>
						<th>经停：</th>
						<td><em id="astop_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_stop[$i]</em></td>
					</tr>
					<tr>
						<th>航班：</th>
						<td><em id="aflight_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_flight[$i] - $a_name[$i]</em></td>
						<th>机型：</th>
						<td><em id="equip_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_equip[$i]</em></td>
					</tr>
					<tr>
						<th>舱位：</th>
						<td><em id="cabin_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_class[$i]</em></td>
						<th>状态：</th>
						<td><em id="astatus_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$order_status</em></td>
					</tr>
					<tr>
						<th>起飞：</th>
						<td><em id="a_dtime_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_dtime[$i](当地时间) $a_depart[$i]$dport0($a_dcity[$i])</em></td>
						<th></th>
						<td><em id="dweather_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$weather{$a_dcity[$i]}</em></td>
					</tr>
					<tr>
						<th>到达：</th>
						<td><em id="a_atime_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_atime[$i](当地时间) $a_arrive[$i]($a_acity[$i])</em></td>
						<th></th>
						<td><em id="aweather_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$weather{$a_acity[$i]}</em></td>
					</tr>
					<tr>
						<th>飞行：</th>
						<td><em id="flighttime_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_dur[$i]</em></td>
						<th>餐食：</th>
						<td><em id="eat_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">__</em></td>
					</tr>
					<tr>
						<th>行李：</th>
						<td colspan=3><em id="bag_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$bag</em></td>
					</tr>`;
		}
		else {
			$html_scheduling .= qq`
					<tr>
						<td><em id="origin_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_depart_e[$i]</em><em id="origine_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_depart[$i]$dport0</em></td>
						<td><em id="bourn_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_arrive_e[$i]</em><em id="bourne_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_arrive[$i]</em></td>
						<td>$a_flight[$i]</td>
						<td><em id="classname_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_class[$i]</em></td>
						<td><em id="status_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">OK</em></td>
						<td>$depart_date[$i]<br />$a_dtime[$i]</td>
						<td>$arrive_date[$i]<br />$a_atime[$i]</td>
						<td><em id="flytime_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_dur[$i]</em></td>`;
					if ($Person_diff eq "0") {
						$html_scheduling .= qq`
						<td><em id="bag_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$bag</em></td>`;
					}
					$html_scheduling .= qq`
					</tr>`;
					if ($Person_diff eq "1") {
						$html_scheduling .= qq`
						<tr>
							<td colspan=8><em id="bag_$i" class="editor" title="点击修改此内容" onclick="insertText(this, 1);" style="text-align:left">行李BAGGAGE: $bag</em></td>
						</tr>	
						`;
					}
		}
	}

	if ($templateheader eq '') {
		$templateheader = qq`<div class="title_div">
								<div class="title_word">
									<h1 class="tcktitle tc">国际机票行程单</h1>
									<h2 class="tcktitle en">ITINERARY</h2>
								</div>
								<div class="title_img">
									<img src="http://www.skyecho.com/admin/images/IATA_logo.gif" height="65" width="115" alt="IATA标志" >
								</div>
							</div>`;
	}

	my $templatecontent = '';
	my $templatestyle = '';
	if ($in{trip} == 4) {
		$templatestyle = qq`
			.main-trip{width:100%;border:#000 solid 1px;border-collapse:collapse;}
			.main-trip tbody th{width:90px;padding:3px 5px;}
			.main-trip tbody td{width: 40%;}
			.main-trip .thead th{width:auto;padding:5px;border:#000 solid 1px;border-bottom:none;text-align:left;background:#ccc;}
			.main-passenger{width:100%;border:#000 solid 1px;margin:5px auto;border-collapse:collapse;}
			.main-passenger th{background:#ccc;border:#000 solid 1px;}
			.main-passenger td{text-align:center;border:#000 solid 1px;}
			`;
		$templatecontent = qq`
			<h5>旅客信息：</h5>
			<table border="1" cellspacing="0" cellpadding="5" align="center" class="main-passenger" id="caption1" onmouseover="Fid('caption1').id='caption1_tmp'; this.id='caption1'; showMenu(this.id, false, 1);">
				<tbody id="tab_content_1">
					<tr>
						<th width="30%">旅客姓名</th>
						<th width="20%">证件类型</th>
						<th width="30%">证件号码</th>
						<th>票号</th>
					</tr>
					$html_personinfo
				</tbody>
			</table>
			<h5>航班信息：</h5>
			<table border="0" cellspacing="0" cellpadding="0" class="main-trip" id="caption2" onmouseover="Fid('caption2').id='caption1_tmp'; this.id='caption2'; showMenu(this.id, false, 1);">
				<tbody id="tab_content_2">
					$html_scheduling
				</tbody>
			</table>`;
	}
	else {
		$templatestyle = qq`
			caption { border: 0; padding: 8px; text-align: left; font-size: 16px; font-family: 黑体; }
			.tab0 td { padding: 3px 8px; }
			.tab0, .tab2, .tab4 { width: 100%; border-collapse: collapse; }
			.tab1, .tab3 { text-align: left; padding: 3px 8px; }
			.tab1 li, .tab3 li { padding: 3px 0; }
			.tab2 { margin-top: 15px; border-bottom: #666 solid 1px; }
			.tab2 th { padding: 8px; text-align: left; font-size: 15px; font-family: 黑体; font-weight: normal; }
			.tab2 td, .tab2 th { padding: 3px; text-align: center; }
			.tab2 th em, .tab2 td em { display: block; }
			.tab3 { margin-top:20px; }
			.tab4 { display: none; }
			.tab4 td { padding: 8px 0 8px 20px; font-size: 15px; }
			.row1 th, .row1 td { border-bottom: #666 solid 1px; }
			th em { white-space: nowrap; font-size: 12px; }
			.title_div { float:left; width:100%; padding-left:32%; } 
			.title_word{ float:left; margin-top:2%;width:25%; }
			.title_img{ float:left; width:30%; }`;
		$templatecontent = qq`
			<div class="content">
				<table border="0" cellspacing="0" cellpadding="0" class="tab1" id="caption1" onmouseover="Fid('caption1').id='caption1_tmp'; this.id='caption1'; showMenu(this.id, false, 1);">
					<tbody id="tab_content_1">
						$html_personinfo
					</tbody>
				</table>
				<table border="0" cellspacing="0" cellpadding="0" class="tab0" id="caption2" onmouseover="Fid('caption2').id='caption2_tmp'; this.id='caption2'; showMenu(this.id, false, 1);">
					<tr id="tab_content_2">
						<td width="50%"><strong><nobr>出票日期(DATE OF ISSUE)：</nobr></strong>$tkt_date</td>
						<td><strong>订座记录编码(AGENT PNR)：</strong><em id="ticketpnr_$ii" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$pnr</em></td>
					</tr>
				</table>
				<table border="0" cellspacing="0" cellpadding="0" class="tab0" id="caption3" onmouseover="Fid('caption3').id='caption3_tmp'; this.id='caption3'; showMenu(this.id, false, 1);">
					<tbody id="tab_content_3">
						<tr>
							<td width="260"><strong>航空公司编码(AIRLINE PNR)：</strong></td><td align="left"><em id="airpnr" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">----</em></td>
						</tr>
						<tr>
							<td width="260"><strong><nobr>出票航空公司(ISSUING AIRLINE)：</nobr></strong></td><td align="left"><em id="airline" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$a_name[0]</em></td>
						</tr>
					</tbody>
				</table>
				<table border="0" cellspacing="0" cellpadding="0" class="tab2" id="caption4" onmouseover="Fid('caption4').id='caption4_tmp'; this.id='caption4'; showMenu(this.id, false, 1);">
					<caption>行程(<em>SCHEDULING</em>)：</caption>
					<tbody id="tab_content_4">
						<tr class="row1">
							<th>始发地<em>ORIGIN</em></th>
							<th>目的地<em>DESTINATION</em></th>
							<th>航班号<em>FLIGHT</em></th>
							<th>舱位<em>CLASS</em></th>
							<th>状态<em>STATUS</em></th>
							<th>起飞时间<em>DEPTIME</em></th>
							<th>到达时间<em>ARRTIME</em></th>
							<th>飞行时间<em>FLIGHT TIME</em></th>`;
						if ($Person_diff eq "0") {
							$templatecontent .= qq`<th>行李<em>BAGGAGE</em></th>`;
						}
						$templatecontent .= qq`	
						</tr>
						$html_scheduling
					</tbody>
				</table>
				<table border="0" cellspacing="0" cellpadding="0" class="tab0 tab3" id="caption5" onmouseover="Fid('caption5').id='caption5_tmp'; this.id='caption5'; showMenu(this.id, false, 1);">
					<tbody id="tab_content_5">
						<tr$price_nshow>
							<td><strong>实收票款(FARE)：</strong></td><td align="left"><em id="fare" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$price_total.00</em></td>
						</tr>
						<tr$price_nshow>
							<td><strong>税　　款(TAX)：</strong></td><td align="left"><em id="tax" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$tax_total.00</em></td>
						</tr>
						<tr$price_nshow>
							<td><strong>服 务 费(SERVICE FEE)：</strong></td><td align="left"><em id="tax" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$Service_fee</em></td>
						</tr>
						<tr$price_nshow>
							<td><strong>实收总额(TOTAL)：</strong></td><td align="left"><em id="total" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$Total</em></td>
						</tr>
						<tr$price_nshow>
							<td width="260"><strong>票价条件(RESTRICTIONS)：</strong></td><td align="left"><em id="rest" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$Pat_rmk</em></td>
						</tr>
						<tr valign="top">
							<td><strong>备　　注(REMARK)：</strong></td><td align="left"><em id="remark" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$comment</em></td>
						</tr>
					</tbody>
				</table>
			</div>
			<table border="0" cellspacing="0" cellpadding="0" class="tab4">
				<tr>
					<td width="50%">销售员：<em id="fare" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">----</em></td>
					<td>旅客签名：</td>
				</tr>
			</table>`;
	}

	##修改字体大小及部分样式 chengzx@2013-8-23
	print qq`
	<style type="text/css" media="print">
	/* media="print" 这个属性可以在打印时有效 */
	/* 不打印 */
	.Noprint{ display: none; }
	/* 分页 */
	.PageNext{ page-break-after: always; }
	</style>
	<style type="text/css" media="screen">
	.wrapper {
		background: #f4f4f4;
	}
	.operation {
		margin: 15px auto;
		text-align: center;
		background: #FFFAD8;
		border: #FFD35D solid 1px;
	}
	.operation button {
		margin: 2px;
		width: 80px;
		cursor: pointer;
	}
	.group { width: 100px; padding: 1px; }
	.grouparea { width: 350px; height: 50px; }
	.editor { background: $editorColor; }
	</style>
	<style type="text/css" media="all">
	body { font-size: 14px; margin: 0px; }
	h1, h2, ul, li { margin: 0; padding: 0; }
	ul, li { list-style: none; }
	em {
		font-style: normal;
		font-family: Geneva, Helvetica;
	}
	strong { font-family: 黑体; font-weight: normal; font-size: 15px; }
	.content { border: #000 solid 0px; height: 700px; }
	.tcktitle {
		width: 100%;
		overflow: hidden;
	}
	h1 {
		text-align: center;
		font-family: 黑体;
		font-size: 25px;
		font-weight: normal;
	}
	h2 {
		text-align: center;
		font-size: 20px;
		margin-bottom: 8px;
	}
	.tips { padding: 3px; text-align: left; font-size: 12px; }
	$templatestyle
	.operation_menu { display: block; margin-left: 700px; width: 80px; border: #cae1ff solid 1px; text-align: center; }
	.operation_menu li, .operation_menu li a { display: block; clear: both; zoom: 1; }
	.operation_menu li a { padding: 5px; }
	.operation_menu li a:link, .operation_menu li a:visited { text-decoration: none; color: #666; }
	.operation_menu li a:hover { background: #f4fbff; color: #090 }
	</style>
	
	</head>
	<body onKeyDown="ctrlMove();" onload="init()">
	<div id="layerbox" style="z-index: 100; left: 10px; top: 10px; width: 700px; position: absolute;">
		<div id="layOutDiv"></div>
		<div id="wrapperDiv" class="wrapper">
			$templateheader
			$templatecontent
			$templatefooter
		</div>
		<div class="operation Noprint">
			<table border="0" cellspacing="0" cellpadding="0" width="100%">
				<tr>
					<td>
						<button onclick="moveItem(0,-4);">上 移 ↑</button><br>
						<button onclick="moveItem(-4,0);">左 移 ←</button>
						<button onclick="moveItem(0,4);">下 移 ↓</button>
						<button onclick="moveItem(4,0);">右 移 →</button>	
					</td>
					<td width="400">
						<div class="tips">提　示：请先把浏览器“打印设置”的边距均调为0。<br />　　　　灰色背景为打印部分，您可以使用键盘方向键进行微调！<br />　　　　蓝色背景的文字可点击修改。<br />　　　　关闭浏览器后需要重新设置打印边距。</div>
						<div class="tips" id="showmargin">左边距：10px<br />上边距：0px</div>
					</td>
					<td><button onclick="printInv()">直接打印</button><button onclick="send_Email();">发送邮件</button></td>
				</tr>
			</table>
			<iframe frameborder="0" id="frm_update" width="0" style="display: none;"></iframe>
		</div>
	</div>
	<ul class="operation_menu Noprint" id="caption1_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_1'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_1'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_1'));">x 恢复默认</a></li>
	</ul>
	<ul class="operation_menu Noprint" id="caption2_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_2'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_2'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_2'));">x 恢复默认</a></li>
	</ul>
	<ul class="operation_menu Noprint" id="caption3_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_3'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_3'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_3'));">x 恢复默认</a></li>
	</ul>
	<ul class="operation_menu Noprint" id="caption4_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_4'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_4'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_4'));">x 恢复默认</a></li>
	</ul>
	<ul class="operation_menu Noprint" id="caption5_menu" style="display: none;">
		<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_5'));">+ 放大字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_5'));">- 缩小字体</a></li>
		<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_5'));">x 恢复默认</a></li>
	</ul>
	<form id="send_body" Method="post">
		<input type='hidden' name="body" id="body_input" value="">
		<input type='hidden' name="User_ID"  value="$in{User_ID}">
		<input type='hidden' name="Serial_no"  value="$in{Serial_no}">
	</form>
	<script>
		function send_Email(){
			var body = document.getElementById("wrapperDiv").innerHTML; 
			document.getElementById("body_input").value=body;
			postwin('send_body','send_itinerary.pl','发送邮件',400,300);
		}
	</script>
	`;
}
elsif ($in{trip} == 3) {	## 发送电子行程单 jeftom @2010-05-12
	for (my $i=0;$i<$air_num;$i++) {
		if ($a_equip[$i] ne "") {
			$sql = "select Flight_name from ctninfo..Equip where Equip = '$a_equip[$i]' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$a_equip[$i]=$row[0];
					}
				}
			}
		}
	}

	### 查询乘客名单			#fanzy@2012-5-22修改航段价格为合计
	#my $res_serial = $a_serial[0];
	#my $personnum = 0;
	#my $memberid = '';	##会员代码
	#my %personinfo = ();

	#if ($Is_inter eq "Y" && $i==$air_num-1) {	$res_serial = 0;		}	## 国际，显示第一航段价格即可	dabin@2009-2-23
	#$sql = "select a.First_name,a.Card_ID,a.Out_price,a.Tax_fee,a.YQ_fee,a.Insure_type,
				#a.Insure_outprice,a.Insure_num,a.Other_fee,a.Out_price+a.Tax_fee+a.YQ_fee+a.Other_fee,a.Dept_ID,
				#a.Air_code,a.Ticket_ID,a.Ticket_LID
			#from ctninfo..Airbook_detail_$Top_corp a
			#where a.Reservation_ID = '$a_resid[0]'
				#and a.Res_serial=$res_serial
			#order by a.Res_serial,a.Ticket_ID ";
	##print "<pre>$sql";
	#$db->ct_execute($sql);
	#while($db->ct_results($restype) == CS_SUCCEED) {
		#if($restype==CS_ROW_RESULT) {
			#while(@row = $db->ct_fetch) {
				#my $insure = 0;
				#if ($row[7] > 0) {
					#$insure = $row[6]*$row[7];
				#}
				#my $tk_id="";
				#if ($row[12] > 0) {	
					#$tk_id="$row[11]-$row[12]";		
					#if ($row[13] > 0) {	$tk_id.="-$row[13]";	}
				#}
				#if ($Is_inter eq "N") {
					#$row[1] = substr($row[1],2,length($row[1])-2);
				#}
				#$row[9] =~ s/\s*\.00//;

				### 数组格式：姓名，证件号码，票号，票价，机建，燃油，保险，其它，合计
				#$personinfo[$personnum]{name} = $row[0];
				#$personinfo[$personnum]{passport} = $row[1];
				#$personinfo[$personnum]{tkt} = $tk_id;
				#$personinfo[$personnum]{fare} = $row[2];
				#$personinfo[$personnum]{tax} = $row[3];
				#$personinfo[$personnum]{yq} = $row[4];
				#$personinfo[$personnum]{insure} = $insure;
				#$personinfo[$personnum]{other} = $row[8];
				#$personinfo[$personnum]{total} = $row[9];

				#$personnum ++;
			#}
		#}
	#}
	## 查询乘客名单						#fanzy@2012-5-22修改航段价格为合计
	my $res_serial = $a_serial[0];
	my %personinfobe = ();
	my @personinfobenum;
	$sql = "select a.First_name,a.Card_ID,a.Out_price,a.Tax_fee,a.YQ_fee,a.Insure_type,
				a.Insure_outprice,a.Insure_num,a.Other_fee,a.Out_price+a.Tax_fee+a.YQ_fee+a.Other_fee,a.Dept_ID,
				a.Air_code,a.Ticket_ID,a.Ticket_LID
			from ctninfo..Airbook_detail_$Top_corp a
			where a.Reservation_ID = '$a_resid[0]'
			order by a.Res_serial,a.Ticket_ID ";
	if ($sqldetail ne "") {
	$sql = "$sqldetail
			select a.First_name,a.Card_ID,a.Out_price,a.Tax_fee,a.YQ_fee,a.Insure_type,
				a.Insure_outprice,a.Insure_num,a.Other_fee,a.Out_price+a.Tax_fee+a.YQ_fee+a.Other_fee,a.Dept_ID,
				a.Air_code,a.Ticket_ID,a.Ticket_LID
			from #tempAirbookdetail a
			order by a.Res_serial,a.Ticket_ID
			drop table #tempAirbookdetail " ;
	}
	#print "<pre>$sql";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT) {
			while(@row = $db->ct_fetch) {
				my $insure = 0;
				if ($row[7] > 0) {
					$insure = $row[6]*$row[7];
				}
				my $tk_id="";
				if ($row[12] > 0) {	
					$tk_id="$row[11]-$row[12]";		
					if ($row[13] > 0) {	$tk_id.="-$row[13]";	}
				}
				if ($Is_inter eq "N") {
					$row[1] = substr($row[1],2,length($row[1])-2);
				}
				$row[9] =~ s/\s*\.00//;

				## 数组格式：姓名，证件号码，票号，票价，机建，燃油，保险，其它，合计
				my $CardID_be=$row[1];
				if ($personinfobe{$CardID_be,name} eq "") {
					$personinfobe{$CardID_be,name}=$row[0];
				}
				if ($personinfobe{$CardID_be,passport} eq "") {
					$personinfobe{$CardID_be,passport}=$row[1];
				}
				if ($personinfobe{$CardID_be,tkt} eq "") {
					$personinfobe{$CardID_be,tkt}=$tk_id;
				}
				$personinfobe{$CardID_be,fare}+=$row[2];
				$personinfobe{$CardID_be,tax}+=$row[3];
				$personinfobe{$CardID_be,yq}+=$row[4];
				$personinfobe{$CardID_be,insure}+=$insure;
				$personinfobe{$CardID_be,other}+=$row[8];
				$personinfobe{$CardID_be,total}+=$row[9];
				push(@personinfobenum,$CardID_be);
			}
		}
	}
	@personinfobenum = grep {++$counts{$_} < 2;} @personinfobenum;
	my $personnum = 0;
	my $memberid = '';	##会员代码
	my %personinfo = ();
	for (my $i=0;$i<scalar(@personinfobenum) ;$i++) {#fanzy@2012-5-22
		my $CardID_be=$personinfobenum[$i];
		$personinfo[$personnum]{name} = $personinfobe{$CardID_be,name};
		$personinfo[$personnum]{passport} = $personinfobe{$CardID_be,passport};
		$personinfo[$personnum]{tkt} = $personinfobe{$CardID_be,tkt};
		$personinfo[$personnum]{fare} = $personinfobe{$CardID_be,fare};
		$personinfo[$personnum]{tax} = $personinfobe{$CardID_be,tax};
		$personinfo[$personnum]{yq} = $personinfobe{$CardID_be,yq};
		$personinfo[$personnum]{insure} = $personinfobe{$CardID_be,insure};
		$personinfo[$personnum]{other} = $personinfobe{$CardID_be,other};
		$personinfo[$personnum]{total} = $personinfobe{$CardID_be,total};
		$personnum++;
	}
	my @airlines = ();
	my @flightno = ();
	for (my $i = 0; $i < scalar(@a_flight); $i++) {
		push(@airlines, $AIRLINESSNAME{substr($a_flight[$i], 0, 2)});
		push(@flightno, $a_flight[$i]);
	}

	my $endorsement;#签注 跟订单走
	$cmb_remark = "<option value=''></option>";
	if ($a_resid[0] ne "") {
		$sql = "select top 10 Remark from ophis..Op_rmk where Res_ID ='$a_resid[0]' and Sales_ID='$Corp_center' and Op_type in ('1','11') and Product_type='A' and Remark not like '%[错误|请求|返点|价格|结算价|政策]%' order by Op_time desc	\n ";
		#print "<pre>$sql";
		my @Op_rmk;
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
					push(@Op_rmk,$row[0]);
				}
			}
		}
	}
	
	my $end_temp=0;
	@Op_rmk = grep {++$counts{$_} < 2;} @Op_rmk;
	for (my $i = 0; $i < scalar(@Op_rmk); $i++) {
		if ($end_temp==0) {
			$endorsement=$Op_rmk[$i];
			$cmb_remark .= "<option value='$Op_rmk[$i]' selected>$Op_rmk[$i]</option>";
		}else {
			$cmb_remark .= "<option value='$Op_rmk[$i]'>$Op_rmk[$i]</option>";
		}
		$end_temp++;
	}
	$cmb_remark .= "<option value='不得签转'>不得签转</option>";
	$cmb_remark .= "<option value='不得签转不得退票'>不得签转不得退票</option>";
	$cmb_remark .= "<option value='不得变更不得签转'>不得变更不得签转</option>";
	$cmb_remark .= "<option value='不得签转变更退票'>不得签转变更退票</option>";
	$cmb_remark .= "<option value='不得更改不得签转不得退票'>不得更改不得签转不得退票</option>";
	$cmb_remark .= "<option value='不得签转仅限原出票地退票'>不得签转仅限原出票地退票</option>";

	## 查询出票模板信息
	my $list_Office_ID = '';
	my $list_BSP_temp = '';
	my $list_Officename_temp = '';
	$sql = "select Office_name,Office_ID,rtrim(BSP)
			from ctninfo..Office_info 
			where (Corp_ID='$Corp_center' or User_ID='$in{User_ID}')
				and Is_insure='Y'
			order by Air_code";
	$o_num = 0;
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{	
				if ($o_num==0) {
					$Office_name = $row[0];
					$BSP = $row[2];
					$list_Office_ID .= qq`<option value="$row[1]" selected>$row[1]</option>`;
				}else{
					$list_Office_ID .= qq`<option value="$row[1]">$row[1]</option>`;
				}
				$list_BSP_temp .= qq`<option value="$row[2]">$row[2]</option>`;
				$list_Officename_temp .= qq`<option value="$row[0]">$row[0]</option>`;
				
				$o_num++;
			}
		}
	}

	## 查询接收邮箱地址
	$sql = "select a.Useremail, b.Email 
			from ctninfo..Airbook_$Top_corp as a, ctninfo..User_info as b
			where a.Reservation_ID='$a_resid[0]'
			and a.Sales_ID='$Corp_center'
			and b.Corp_num='$Corp_center'
			and a.User_ID=b.User_ID";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{	
				$usermail = $row[0] eq '' ? $row[1] : $row[0];
			}
		}
	}

	## 日期处理
	my $today = &cctime(time);
	my ($week,$month,$day,$time,$year) = split(" ",$today);
	if($day<10){$day="0".$day;}
	$today = $year."-".$month."-"."$day";

	print qq`
	<style media="screen">
		body{ font-size: 12px; }
		em {
			font-size: 8px;
			font-style: normal;
			font-family: Geneva, Helvetica;
		}
		input {
			height: 16px;
			border: #ccc solid 1px;
		}
		select {font-size:12px;}
		.wrapper {
			width: 780px;
			margin: 0px auto;
			background: #f8f8f8;
		}
		.tcktitle {
			width: 100%;
			height: 60px;
		}
		.tcktitle .tl {
			width: 230px;
		}
		.tcktitle .tc {
			text-align: center;
			font-family: 黑体;
			font-size: 18px;
		}
		.tcktitle .tc em {
			font-size: 11px;
		}
		.tcktitle .tr {
			width: 230px;
		}
		.tab1 {
			width: 100%;
			height: 40px;
		}
		.tab2 {
			width: 100%;
			height: 30px;
			border-top: #ccc solid 1px;
			margin-top: 3px;
		}
		.tab3 {
			width: 100%;
			height: 40px;
			border-top: #ccc solid 1px;
			margin-top: 3px;
		}
		.tab4 {
			width: 100%;
			height: 40px;
			border-top: #ccc solid 1px;
			margin-top: 3px;
		}
		.tab5 {
			width: 780px;
			margin-top: 10px;
			padding: 10px 0px;
			background: #f8f8f8;
		}
		.row1 {
			height: 30px;
			text-align: center;
		}
		.row1 td {
			border-bottom: #ccc solid 1px;
		}
		.row2 {
			height: 30px;
		}
		.row3 {
			height: 30px;
		}
		.row4 {
			height: 30px;
		}
		.row5 {
			height: 30px;
		}
		.row6 {
			height: 30px;
		}

		.etkt1 {
			width: 75px;
		}
		.etkt2 {
			width: 120px;
		}
		.CK1 {
			width: 45px;
		}
		.CK2 {
			width: 120px;
		}
		.CT1 {
			width: 80px;
		}
		.CT2 {
		}
		.INS1 {
			width: 50px;
		}
		.INS2 {
			width: 100px;
		}
		.AC1 {
			width: 75px;
		}
		.AC2 {
			width: 120px;
		}
		.IB1 {
			width: 65px;
		}
		.IB2 {
		}
		.ID1 {
			width: 65px;
		}
		.ID2 {
			width: 100px;
		}

		.tabp {
			border: #ccc solid 0px;
			width: 100%;
		}
		.tabp td {
			padding: 1px;
		}
		.tdp
		{
			border-bottom: 1 solid #000000;
			border-left:  1 solid #000000;
			border-right:  0 solid #ffffff;
			border-top: 0 solid #ffffff;
		}
		.print_no {
			border: #ccc solid 1px;
		}
		.inputStyle_fare {
			width: 90px;
		}
		.inputStyle_1 {
			width:170px;
		}
		.inputStyle_2 {
			width: 60px;
			border: #ff9000 solid 1px;
		}
		.inputStyle_3 {
			width: 70px;
		}
		.inputStyle_4 {
			width: 33px;
		}
		.inputStyle_5 {
			width: 33px;
		}
		.inputStyle_6 {
			width: 60px;
		}
		.inputStyle_7 {
			width: 38px;
		}
		.inputStyle_8 {
			width: 60px;
		}
		.inputStyle_9 {
			width: 70px;
		}
		.inputStyle_10 {
			width: 80px;
		}
		.inputStyle_11 {
			width: 100px;
		}
		.inputStyle_12 {
			width: 70px;
		}
		.inputStyle_13 {
			width: 75px;
		}
		.inputStyle_14 {
			width: 35px;
		}
		.inputStyle_15 {
			width: 100px;
		}
		.inputStyle_16 {
			width: 100px;
		}
		.inputStyle_17 {
			width: 100px;
		}
		.inputStyle_18 {
			width: 100px;
		}
		.inputStyle_19 {
			width: 100px;
		}
		.inputStyle_20 {
			width: 250px;
		}
		.inputStyle_21 {
			width: 100px;
		}
		.tips {
			text-align: left;
		}
		.byname {
			width: 170px;
			color: blue;
		}
		.btn_more {
			width:60px;
			height: 20px;
			line-height: 20px;
			cursor: pointer;
			text-decoration: none;
		}
		.btn_more1 {
			height: 28px;
			line-height: 25px;
			cursor: pointer;
			text-decoration: none;
		}
		.btn_msg {height:22px; width:80px; border:#C1C0B4 solid 1px;}
	</style>
	<script type="text/javascript">
	// 过滤空格
	function trim(str) {
		return (str + '').replace(/(\\s+)\$/g, '').replace(/^\\s+/g, '');
	}
	function checkForm()
	{
		if (document.getElementById('email').value == '') {
			alert('请输入电子邮箱地址！');
			document.getElementById('email').focus();
			return false;
		}
		var e_value = document.getElementById('email').value;
		e_value = trim(e_value);
		var myreg = /^([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+@([a-zA-Z0-9]+[_|\_|\.]?)*[a-zA-Z0-9]+\.[a-zA-Z]{2,3}\$/;
		if (!myreg.test(e_value)) {
			alert("请输入有效的电子邮件地址");
			document.getElementById('email').focus();
			return false;
		}
	}
	function change_cmt(selectobj, inputobj){
		var prod = document.getElementById(selectobj).options[document.getElementById(selectobj).selectedIndex].text;
		document.getElementById(inputobj).value = prod;
	}
	function source_cmt(Office_ID, BSP_temp,BSP,Officename_temp,Office_name){
		var id=document.getElementById(Office_ID).selectedIndex;
		document.getElementById(BSP_temp).selectedIndex=id;
		document.getElementById(Officename_temp).selectedIndex=id;
		document.getElementById(BSP).value=document.getElementById(BSP_temp).value;
		document.getElementById(Office_name).value=document.getElementById(Officename_temp).value;
	}
	</script>

	<form action="send_trip.pl" method="post" name="query" target="_blank" onsubmit="return checkForm();">
		<div class="wrapper">
			<table border="0" cellspacing="0" cellpadding="0" class="tcktitle">
				<tr>
					<td class="tl"></td>
					<td class="tc">航空运输电子客票行程单<br /><em>ITINERARY/RECEIPT OF E-TICKET<br />FOR AIR TRANSPORTION</td>
					<td class="tr"></td>
				</tr>
			</table>
		</div>`;
		##显示航站楼 dingwz@2014-07-31
        my($dport0,$aport0)=split(',',$air_port[0]);
		$dport0 =~ s/^\s+|\s+$//g;
		$aport0 =~ s/^\s+|\s+$//g;
		if($dport0 ne ""){$dport0="$dport0号航站楼";}
		if($aport0 ne ""){$aport0="$aport0号航站楼";}
		
		my($dport1,$aport1)=split($air_port[1],',');
		$dport1 =~ s/^\s+|\s+$//g;
		$aport1 =~ s/^\s+|\s+$//g;
		if($dport1 ne ""){$dport1="$dport1号航站楼";}
		if($aport1 ne ""){$aport1="$aport1号航站楼";}
		
		my($dport2,$aport2)=split($air_port[2],',');
		$dport2 =~ s/^\s+|\s+$//g;
		$aport2 =~ s/^\s+|\s+$//g;
		if($dport2 ne ""){$dport2="$dport2号航站楼";}
		if($aport2 ne ""){$aport2="$aport2号航站楼";}
		
		for (my $i = 0; $i < $personnum; $i++) {
			print qq`
			<div class="wrapper" style="margin: 2px auto; border-top: #ff0000 solid 2px;">
				<table border="0" cellspacing="0" cellpadding="0" class="tab1">
					<tr>
						<td>旅客姓名</td>
						<td><input name="customName_$i" type="text" class="inputStyle_1" value="$personinfo[$i]{name}" /></td>
						<td>有效身份证件号码</td>
						<td><input name="passportID_$i" type="text" class="inputStyle_1" value="$personinfo[$i]{passport}" /></td>
						<td>签注</td>
						<td><input name="cmb_remark_$i" id="cmb_remark_$i" type="text" class="inputStyle_1" value="$endorsement" style="position:relative;width:140px;z-index:10;" />
							<span style="border:0px solid red;"><iframe frameborder="0" scrolling="no" height="19" style="position:absolute;margin-left:-145px;width:140px;height:19px;z-index:4;overflow:hidden;"></iframe><select name="cmb_list_$i" id="cmb_list_$i" style="position:absolute;margin-left:-145px;width:157px;z-index:2;" onchange="change_cmt('cmb_list_$i', 'cmb_remark_$i')">$cmb_remark</select></td>
					</tr>
				</table>
				<table border="0" cellspacing="0" cellpadding="0" class="tab2">
					<tr class="row1">
						<td>订座记录</td>
						<td colspan="2"><input type="text" name="PNR_$i" class="inputStyle_2" value="$pnr" /></td>
						<td>承运人<br /><em>CARRIER</em></td>
						<td>航班号<br /><em>FLIGHT</em></td>
						<td>舱位等级<br /><em>CLASS</em></td>
						<td>日期<br /><em>DATE</em></td>
						<td>时间<br /><em>TIME</em></td>
						<td>客票级别/客票类别<br /><em>FARE BASIS</em></td>
						<td>客票生效日期<br /><em>NOT VALID BEFORE</em></td>
						<td> 有效截止日期<br /><em>NOT VALID AFTER</em></td>
						<td>免费行李<br /><em>ALLOW</em></td>
					</tr>
					<tr class="row2">
						<td>自<em>FROM</em></td>
						<td><input name="ed_1c_$i" type="text" class="inputStyle_3" value="$departcity[0]$dport0" /></td>
						<td><input name="ed_1d_$i" type="text" class="inputStyle_4" value="$a_dcity[0]"/></td>
						<td><input name="ed_1a_$i" type="text" class="inputStyle_5" value="$airlines[0]"/></td>
						<td><input name="ed_1f_$i" type="text" class="inputStyle_6" value="$flightno[0]"/></td>
						<td><input name="ed_1s_$i" type="text" class="inputStyle_7" value="$a_class[0]"/></td>
						<td><input name="ed_1dt_$i" type="text" class="inputStyle_8"  value="$departdate[0]"/></td>
						<td><input name="ed_1t_$i" type="text" class="inputStyle_10" value="$departtime[0]"/></td>
						<td><input name="ed_1l_$i" type="text" class="inputStyle_11" value=""/></td>
						<td><input name="ed_1m_$i" type="text" class="inputStyle_12" value=""/></td>
						<td><input name="ed_1n_$i" type="text" class="inputStyle_13" value=""/></td>
						<td><input name="ed_1b_$i" type="text" class="inputStyle_14" value=""/></td>
					</tr>
					<tr class="row3">
						<td>至TO</td>
						<td><input name="ed_2c_$i" type="text" class="inputStyle_3" value="$arrivecity[0]$aport0" /></td>
						<td><input name="ed_2d_$i" type="text" class="inputStyle_4" value="$a_acity[0]"/></td>
						<td><input name="ed_2a_$i" type="text" class="inputStyle_5" value="$airlines[1]"/></td>
						<td><input name="ed_2f_$i" type="text" class="inputStyle_6" value="$flightno[1]"/></td>
						<td><input name="ed_2s_$i" type="text" class="inputStyle_7" value="$a_class[1]"/></td>
						<td><input name="ed_2dt_$i" type="text" class="inputStyle_8" value="$departdate[1]"/></td>
						<td><input name="ed_2t_$i" type="text" class="inputStyle_10" value="$departtime[1]"/></td>
						<td><input name="ed_2l_$i" type="text" class="inputStyle_11" value=""/></td>
						<td><input name="ed_2m_$i" type="text" class="inputStyle_12" value=""/></td>
						<td><input name="ed_2n_$i" type="text" class="inputStyle_13" value=""/></td>
						<td><input name="ed_2b_$i" type="text" class="inputStyle_14" value=""/></td>
					</tr>
					<tr class="row4">
						<td>至TO</td>
						<td><input name="ed_3c_$i" type="text" class="inputStyle_3" value="$arrivecity[1]$aport1" /></td>
						<td><input name="ed_3d_$i" type="text" class="inputStyle_4" value="$a_acity[1]"/></td>
						<td><input name="ed_3a_$i" type="text" class="inputStyle_5" value="$airlines[2]"/></td>
						<td><input name="ed_3f_$i" type="text" class="inputStyle_6" value="$flightno[2]"/></td>
						<td><input name="ed_3s_$i" type="text" class="inputStyle_7" value="$a_class[2]"/></td>
						<td><input name="ed_3dt_$i" type="text" class="inputStyle_8" value="$departdate[2]"/></td>
						<td><input name="ed_3t_$i" type="text" class="inputStyle_10" value="$departtime[2]"/></td>
						<td><input name="ed_3l_$i" type="text" class="inputStyle_11" value=""/></td>
						<td><input name="ed_3m_$i" type="text" class="inputStyle_13" value=""/></td>
						<td><input name="ed_3n_$i" type="text" class="inputStyle_13" value=""/></td>
						<td><input name="ed_3b_$i" type="text" class="inputStyle_14" value=""/></td>
					</tr>
					<tr class="row5">
						<td>至TO</td>
						<td><input name="ed_4c_$i" type="text" class="inputStyle_3" value="$arrivecity[2]$aport2" /></td>
						<td><input name="ed_4d_$i" type="text" class="inputStyle_4" value="$a_acity[2]"/></td>
						<td><input name="ed_4a_$i" type="text" class="inputStyle_5" value="$airlines[3]"/></td>
						<td><input name="ed_4f_$i" type="text" class="inputStyle_6" value="$flightno[3]"/></td>
						<td><input name="ed_4s_$i" type="text" class="inputStyle_7" value="$a_class[3]"/></td>
						<td><input name="ed_4dt_$i" type="text" class="inputStyle_8" value="$departdate[3]"/></td>
						<td><input name="ed_4t_$i" type="text" class="inputStyle_10" value="$departtime[3]"/></td>
						<td><input name="ed_4l_$i" type="text" class="inputStyle_11" value=""/></td>
						<td><input name="ed_4m_$i" type="text" class="inputStyle_13" value=""/></td>
						<td><input name="ed_4n_$i" type="text" class="inputStyle_13" value=""/></td>
						<td><input name="ed_4b_$i" type="text" class="inputStyle_14" value=""/></td>
					</tr>
					<tr class="row6">
						<td>至TO</td>
						<td colspan="2"><input name="ed_5c_$i" type="text" class="inputStyle_3" value="$ed_5c" /></td>
						<td colspan="2"$price_nshow>票 价<br /><input name="ed_fare_$i" type="text" class="inputStyle_fare" value="$personinfo[$i]{fare}" /></td>
						<td colspan="2"$price_nshow>机场建设费<br /><input name="ed_tax_$i" type="text" class="inputStyle_fare" value="$personinfo[$i]{tax}" /></td>
						<td colspan="2"$price_nshow>
							<table width="100%" border="0" cellspacing="0" cellpadding="0">
								<tr>
									<td>燃油附加费<br /><input name="ed_yq_$i" type="text" class="inputStyle_fare" value="$personinfo[$i]{yq}" /></td>
									<td>其他税费<br /><input name="OTHER_$i" type="text" class="inputStyle_fare" value="$personinfo[$i]{other}"/></td>
								</tr>
							</table>
						</td>
						<td colspan="3"$price_nshow>合计<em>TOTAL</em><br /><input name="ed_total_$i" type="text" class="inputStyle_12" value="$personinfo[$i]{total}" /></td>
					</tr>
				</table>
				<table border="0" cellspacing="0" cellpadding="0" class="tab3">
					<tr>
						<td class="etkt1">电子客票号码<br /><em>E-TICKET NO</em></td>
						<td class="etkt2"><input name="ed_tkt_$i" type="text" class="inputStyle_15" value="$personinfo[$i]{tkt}" /></td>
						<td class="CK1">验证码<br /><em>CK</em></td>
						<td class="CK2"><input name="ed_ver_$i" type="text" class="inputStyle_16" value="" /></td>
						<td class="CT1">连续客票<br /><em>CONJUNCTION TKT</em></td>
						<td class="CT2"><input name="ed_con_$i" type="text" class="inputStyle_17" /></td>
						<td class="INS1"$price_nshow>保险费<br /><em>INSURANCE</em></td>
						<td class="INS2"$price_nshow><input name="ed_insure_$i" type="text" class="inputStyle_18" value="$personinfo[$i]{insure}" /></td>
					</tr>
				</table>
				<table border="0" cellspacing="0" cellpadding="0" class="tab4">
					<tr>
						<td class="AC1">销售单位代号<br /><em>AGENT CODE</em></td>
						<td class="AC2"><select name="Office_ID_$i" id="Office_ID_$i" class="inputStyle_19" onchange="source_cmt('Office_ID_$i', 'BSP_temp_$i','BSP_$i','Officename_temp_$i','Office_name_$i')">$list_Office_ID</select><select name="BSP_temp_$i" id="BSP_temp_$i" style='display:none'>$list_BSP_temp</select><input name="BSP_$i" id="BSP_$i" type="hidden"  value="$BSP"/></td>
						<td class="IB1">填开单位<br /><em>ISSUED BY</em></td>
						<td class="IB2"><select name="Officename_temp_$i" id="Officename_temp_$i" style='display:none'>$list_Officename_temp</select><input name="Office_name_$i" id="Office_name_$i" type="text" class="inputStyle_20" value="$Office_name"/></td>
						<td class="ID1">填开日期<br /><em>ISSUED DATE</em></td>
						<td class="ID2"><input name="ed_date_$i" type="text" class="inputStyle_21" value="$today" /></td>
					</tr>
				</table>
			</div>`;
		}

		print qq`
		<div class="wrapper Noprint" style="margin-top:5px;">
			<table border="0" cellspacing="0" cellpadding="0" class="tab5">
				<tr>
					<td>备注信息：<textarea name="comment" style="width: 500px; height: 50px;vertical-align:middle; border:#ccc solid 1px;">$comment</textarea></td>
				</tr>
				<tr>
					<td>接收邮箱：<input type="text" name="email" id="email" value="$usermail" style="padding: 5px; width:200px;" /> <input type="submit" class="btn_more1" value="预览并发送邮件" /></td>
				</tr>
			</table>
		</div>
		<input type="hidden" name="User_ID" value="$in{User_ID}" />
		<input type="hidden" name="Serial_no" value="$in{Serial_no}" />
		<input type="hidden" name="personnum" value="$personnum" />
	</form>`;
}
else {	## 国内机票行程单
	if ($in{relate_num} > 0 && $resid[0] ne "" && $in{associate} eq "Y") {
		&show_air_js();
		print qq`
		<div id="showOrderAlert" class="Noprint">
			<form action='air_trip_ok.pl' method="get">
				<table width="100%" border=0 cellpadding=0 cellspacing=0>
					<tr><td colspan=2><font color=red>提示：此订单有 $in{relate_num} 个关联订单，请确认是否同时打印以下选中的关联订单内容？</font></td></tr>
					<tr><td height=28>`;
		foreach $capword (sort keys(%in)) {
			print "<input type=hidden name='$capword' value='$in{$capword}'>\n";
		}
		for (my $i=0;$i<$in{relate_num};$i++) {
			print qq`<input type="checkbox" name="ck_$i" value="$resid[$i]" checked /><a href="javascript:Show_book('$resid[$i]')" title='查看订单'>$resid[$i]</a>　`;
		}		
		print qq!</td>
					<td align="right"><input type=submit value=' 确 认 '> <input type="button" value=" 关 闭 " onclick="closeItem('showOrderAlert')" /></td>
				</tr>
				</table>
			</form>
		</div>!;
	}
	
	## ---------------------------------------------------------------------
	## trip : 0 样式一，1 样式二，2 样式三
	if ($in{trip} eq '0') {	## 样式一
		&Title("行程单");
		print qq!
		<link rel='stylesheet' href='/style.css' type='text/css' />
		<center>
		<style type='text/css'>table, td {text-align: left; }</style>
		<script language="javascript">
		function goPrint(){
			window.open('/print.htm','win')
		}
		</script>!;
		print qq!
		<table width=650 border=0 cellpadding=0 cellspacing=0>
		<tr bgcolor=f0f0f0>
			<td align=right height=22 colspan=4><img src='/admin/index/images/print.gif' align=absmiddle> <a href="javascript:goPrint()">打印行程单</a> <a href="$forward&trip=2">换样式三</a></td>
		</tr>
		</table>
		<span id='printTitle'></span>
		<span id='printSpan'>
		<table border=0 width=650 cellpadding=0 cellspacing=0>
			<tr>
				<td>$templateheader
					<table border=0 width=100% cellpadding=0 cellspacing=0>
						<tr><td valign=top>$template</td>
						<td valign=top>$corp_logo</td></tr>
					</table>
				</td>
			</tr>
		<tr><td height=4></td></tr>
		<tr><td height=34><b>航班信息：</b><br><img src='/images/border_top.gif'></td></tr>
		<tr><td align=center><table border=0 width=98% cellpadding=0 cellspacing=0>!;
	}
	my $html_scheduling = '';
	my %totalprice = ();
	for (my $i=0;$i<$air_num;$i++) {
		if ($a_equip[$i] ne "") {
			$sql = "select Flight_name from ctninfo..Equip where Equip = '$a_equip[$i]' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$a_equip[$i]=$row[0];
					}
				}
			}
			#$a_equip[$i] = "机型：$a_equip[$i]";
		}
		if ($in{trip} eq '0') {
			print "<tr bgcolor=white>\n";
		}
		else {
			$html_scheduling .= qq`<table border="0" cellspacing="0" cellpadding="0" width="100%" class="tripbox">\n\t<tr>`;
		}

		if ($Is_inter eq "Y") {
			if ($in{trip} eq '0') {
				print "<td rowspan=2>&nbsp;</td>\n";
			}
			else {
				$html_scheduling .= qq`<td rowspan="3">&nbsp;</td>`;
			}
		}
		else{
			if ($in{trip} eq '0') {
				print "<td rowspan=2><img src='$a_logo[$i]' align=absmiddle></td>\n";
			}
			else {
				$html_scheduling .= qq`<td rowspan="3" valign="top"><img src="$a_logo[$i]" align="absmiddle" /></td>`;
			}
		}
		##显示航站楼 dingwz@2014-07-31
		my($depart_term,$arrive_term)=split(',',$air_port[$i]);
		$depart_term =~ s/^\s+|\s+$//g;
		$arrive_term =~ s/^\s+|\s+$//g;
		if($depart_term ne ""){
		    #$depart_term="T$depart_term";
			$depart_term="<br/>$depart_term号航站楼";
		}
		if($arrive_term ne ""){
		    #$arrive_term="T$arrive_term";
			$arrive_term="<br/>$arrive_term号航站楼";
		}
		##my $air_port = (&is_int($air_port[$i]) == 1) ? "$air_port[$i]号航站楼" : "";	## 显示登机航站楼
		if ($in{trip} eq '0') {
			print "<td height=20 style='vertical-align:top;'>$a_date[$i]（$a_week[$i]）</td>
			<td style='vertical-align:top;'>$a_depart[$i] $a_dtime[$i] 起飞$depart_term</td>
			<td style='vertical-align:top;'>$a_arrive[$i] $a_atime[$i] 到达$arrive_term</td>
			<td align=right style='vertical-align:top;'>历时$a_dur[$i]</td>
			</tr>
			<tr>	
			<td height=20 colspan=4>$a_name[$i] <b>$a_flight[$i]</b> （<b>$a_class[$i]</b>）$a_stop[$i] $a_equip[$i]</td>	
			</tr>";
		}
		else {
			$html_scheduling .= qq`
				<td style='vertical-align:top;'><nobr>$a_date[$i]（$a_week[$i]）</nobr></td>
				<td style='vertical-align:top;'><nobr>$a_depart[$i] $a_dtime[$i] 起飞</nobr>$depart_term</td>
				<td style='vertical-align:top;'><nobr>$a_arrive[$i] $a_atime[$i] 到达</nobr>$arrive_term</td>
				<td align="right" style='vertical-align:top;'><nobr>历时$a_dur[$i]</nobr></td>
			</tr>
			<tr>	
				<td colspan="5">$a_name[$i] <b>$a_flight[$i]</b> （<b>$a_class[$i]</b>）$a_stop[$i] $a_equip[$i]</td>	
			</tr>`;
		}

		if ($Is_inter eq "N" || ($Is_inter eq "Y" && $i==$air_num-1)) {	## 国内航班
			my $pe_name=($Corp_center eq "SIA107")?"销售价":"票价";
			my $pe_style=($Corp_center eq "SIA107")?" style='display: none;'":"";
			if ($in{trip} eq '0') {
				print "<tr><td>&nbsp;</td><td colspan=4>
					<table border=0 width=100% cellpadding=0 cellspacing=0>
					<tr align=center><td height=20>姓名</td>
					<td>证件号码</td>
					<td>票号</td>
					<td width=50$price_nshow>$pe_name</td>
					<td width=50$price_nshow>机场税</td>
					<td width=50$price_nshow>燃油税</td>
					<td width=40$price_nshow>保险</td>
					<td width=40$price_nshow>其它</td>
					<td $pe_style width=50$price_nshow>服务费</td>
					<td width=50$price_nshow>小计</td></tr>";
			}
			else {
				my $name_align=($price_nshow eq "")?" style='text-align: right;'":" style='text-align: left;'";
				$html_scheduling .= qq`
				<tr>
					<td colspan="5">
						<table border="0" cellpadding="0" cellspacing="0" width="100%" class="person">
							<tr$name_align>
								<td>姓名</td>
								<td>证件号码</td>
								<td>票号</td>
								<td$price_nshow>$pe_name</td>
								<td width="50"$price_nshow>机场税</td>
								<td width="50"$price_nshow>燃油税</td>
								<td width="40"$price_nshow>保险</td>
								<td width="40"$price_nshow>其它</td>
								<td $pe_style width="50"$price_nshow>服务费</td>
								<td width="50"$price_nshow>小计</td>
							</tr>`;
			}
			## 查询乘客名单
			my $res_serial = $a_serial[$i];
			my $personnum = 0;
			if ($Is_inter eq "Y" && $i==$air_num-1) {	$res_serial = 0;		}	## 国际，显示第一航段价格即可	dabin@2009-2-23
			$sql = "select a.First_name,a.Card_ID,a.Out_price,a.Tax_fee,a.YQ_fee,a.Insure_type,
						a.Insure_outprice,a.Insure_num,a.Other_fee,a.Out_price+a.Tax_fee+a.YQ_fee+a.Other_fee,a.Dept_ID,
						a.Air_code,a.Ticket_ID,a.Ticket_LID,isnull(a.Service_fee,0)
					from ctninfo..Airbook_detail_$Top_corp a
					where a.Reservation_ID = '$a_resid[$i]'	
						and a.Res_serial=$res_serial 
					order by a.Res_serial,a.Ticket_ID" ;
			if ($sqldetail ne "") {
			$sql = "$sqldetail
					select a.First_name,a.Card_ID,a.Out_price,a.Tax_fee,a.YQ_fee,a.Insure_type,
						a.Insure_outprice,a.Insure_num,a.Other_fee,a.Out_price+a.Tax_fee+a.YQ_fee+a.Other_fee,a.Dept_ID,
						a.Air_code,a.Ticket_ID,a.Ticket_LID,isnull(a.Service_fee,0)
					from #tempAirbookdetail a
					where a.Res_serial=$res_serial
					order by a.Res_serial,a.Ticket_ID
					drop table #tempAirbookdetail " ;
			}
			#print "<pre>$sql";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT) {
					while(@row = $db->ct_fetch) {
						if ($Corp_center eq "SIA107") {
							$row[2]=$row[2]+$row[14];
						}
						$row[9]=$row[9]+$row[14];
						my $insure = 0;
						if ($row[7] > 0) {
							$insure = $row[6]*$row[7];
							$insure .= "元";
							if ($row[5] eq "F") {	$insure = "赠送";		}
							else{ $row[9] = $row[9]+$insure; }
						}
						my $tk_id="";
						if ($row[12] > 0) {	
							$tk_id="$row[11]-$row[12]";		
							if ($row[13] > 0) {	$tk_id.="-$row[13]";	}
						}
						if ($Is_inter eq "N") {
							$row[1] = substr($row[1],2,length($row[1])-2);
						}
						$row[9] =~ s/\s*\.00//;

						my $rowid = $i . $personnum;

						if ($in{trip} eq '0') {
							print qq`<tr align="right">
								<td height="20" align="left">$row[0]</td>
								<td align="left">$row[1]</td>
								<td align="center">$tk_id</td>
								<td$price_nshow>$row[2]元</td>
								<td$price_nshow>$row[3]元</td>
								<td$price_nshow>$row[4]元</td>
								<td$price_nshow>$insure</td>
								<td$price_nshow>$row[8]元</td>
								<td $pe_style $price_nshow>$row[14]元</td>
								<td$price_nshow>$row[9]元</td>
							</tr>`;
						}
						else {
							$html_scheduling .= qq`
							<tr align="right">
								<td height="20" align="left">$row[0]</td>
								<td align="left">$row[1]</td>
								<td align="center">$tk_id</td>
								<td$price_nshow><em id="tkprice_$rowid" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[2]元</em></td>
								<td$price_nshow><em id="taxprice_$rowid" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[3]元</em></td>
								<td$price_nshow><em id="yqprice_$rowid" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[4]元</em></td>
								<td$price_nshow><em id="insprice_$rowid" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$insure元</em></td>
								<td$price_nshow><em id="otherprice_$rowid" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[8]元</em></td>
								<td $pe_style $price_nshow><em id="servicefee_$rowid" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[14]元</em></td>
								<td$price_nshow><em id="numprice_$rowid" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[9]元</em></td>
							</tr>`;

							## 总计 jeftom @2010-12-8
							$totalprice{tkprice} += $row[2];
							$totalprice{taxprice} += $row[3];
							$totalprice{yqprice} += $row[4];
							$totalprice{insprice} += $insure;
							$totalprice{otherprice} += $row[8];
							$totalprice{servicefee} += $row[14];
							$totalprice{numprice} += $row[9];
						}
						$personnum ++;
					}
				}
			}

			if ($in{trip} eq '0') {
				print "</table></td></tr>";
			}
			else {
				$html_scheduling .= qq`</table>\n\t\t</td>\n\t</tr>`;
			}
		}

		if ($in{trip} ne '0' || $in{trip} ne '1') {
			$html_scheduling .= qq`</table>`;
		}
	}
	if ($in{trip} eq '0') {
		print "</table>
		<img src='/images/border_bottom.gif'></td></tr>";
	}
	if ($in{trip} ne '0' || $in{trip} ne '1') {
		$html_scheduling .= qq`
			<table border="0" cellpadding="0" cellspacing="0" width="100%" class="person"$price_nshow>
				<tr>
					<td>&nbsp;</td>
					<td>&nbsp;</td>
					<td>&nbsp;</td>
					<td>票价合计</td>
					<td width="70">机场税合计</td>
					<td width="70">燃油税合计</td>
					<td width="60">保险合计</td>
					<td width="60">其它合计</td>
					<td $pe_style width="70">服务费合计</td>
					<td width="60">总价合计</td>
				</tr>
				<tr style="text-align: right;">
					<td></td>
					<td></td>
					<td></td>
					<td width="60"><em id="tkprice_total" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$totalprice{tkprice}元</em></td>
					<td width="50"><em id="taxprice_total" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$totalprice{taxprice}元</em></td>
					<td width="50"><em id="yqprice_total" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$totalprice{yqprice}元</em></td>
					<td width="40"><em id="insprice_total" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$totalprice{insprice}元</em></td>
					<td width="40"><em id="otherprice_total" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$totalprice{otherprice}元</em></td>
					<td $pe_style width="40"><em id="servicefee_total" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$totalprice{servicefee}元</em></td>
					<td width="60"><em id="numprice_total" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$totalprice{numprice}元</em></td>
				</tr>
			</table>`;
	}

	## ---------------------------------------------------------------------
	## 天气预报
	## ---------------------------------------------------------------------

	my $html_weather = '';
	if ($in{trip} eq '0') {
		print "<tr><td height=34><b>天气预报：</b><br><img src='/images/border_top.gif'></td></tr>
		<tr><td align=center>
		<table border=0 width=98% cellpadding=0 cellspacing=0>";
	}
	else {
		$html_weather = qq`<table border="0" width="100%" cellpadding="0" cellspacing="0">`;
	}
	for ($i=0;$i<$air_num;$i++) {
		my $w_date = substr($a_date[$i],6,2).substr($a_date[$i],10,2);
		## 出发城市
		my $s_date = $t_date;	my $d_name=$today;
		if ($d_add[$i] >=0 && $d_add[$i] < 3) {	$s_date = $w_date;	$d_name=$a_date[$i];	}	## 最近三天
		my $find = 0;
		for ($j=0;$j<scalar(@dis_date);$j++) {
			if ($dis_date[$j] eq $s_date && $dis_city[$j] eq $a_dcity[$i]) {	## 相同城市，不再显示
				$find = 1;
			}
		}

		if ($find == 0) {		
			push(@dis_date,$s_date);	push(@dis_city,$a_dcity[$i]);
			$sql = "select City_name,Min_tmp,Max_tmp,Weather,Cloud from ctninfo..Weather where City_ID='$a_dcity[$i]' and W_date='$s_date' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT) {
					while(@row = $db->ct_fetch) {
						if ($in{trip} eq '0') {
							print "<tr><td height=20 width=110>$d_name：</td><td width=60>$row[0]</td>
							<td width=60>$row[1]－$row[2]℃</td>
							<td width=100>$row[3]</td><td width=370>$row[4]</td></tr>";
						}
						else {
							$html_weather .= qq`
							<tr>
								<td width="115" class="nobr"><nobr>$d_name：</nobr></td>
								<td width="100">$row[0]</td>
								<td width="100">$row[1]－$row[2]℃</td>
								<td width="100">$row[3]</td>
								<td>$row[4]</td>
							</tr>`;
						}
						$find ++;
					}
				}
			}
			if ($find == 0 && ($User_type eq "O" || $User_type eq "S")) {
				if ($in{trip} eq '0') {
					print "<tr><td height=20 width=110>$d_name：</td>
					<td colspan=5><font color=red>$cityname{$a_dcity[$i]} <a href='/cgishell/client/air_other.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&OD=WF:$a_dcity[$i]&dis=W' target=_wf title='查询天气预报'><font color=red>无当日天气信息</a></td>
					</tr>";
				}
				else {
					$html_weather .= qq`
					<tr>
						<td width="115" class="nobr"><nobr>$d_name：</nobr></td>
						<td colspan="5" style="color: red;">$cityname{$a_dcity[$i]} <a href='/cgishell/client/air_other.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&OD=WF:$a_dcity[$i]&dis=W' target=_wf title='查询天气预报'>无当日天气信息</a></td>
					</tr>`;
				}
			}
		}
		## 抵达城市
		$s_date = $t_date;	$d_name=$today;
		if ($d_add[$i] >=0 && $d_add[$i] < 3) {	$s_date = $w_date;	$d_name=$a_date[$i];	}	## 最近三天
		$find = 0;
		for ($j=0;$j<scalar(@dis_date);$j++) {
			if ($dis_date[$j] eq $s_date && $dis_city[$j] eq $a_acity[$i]) {	## 相同城市，不再显示
				$find = 1;
			}
		}
		if ($find == 0) {	
			push(@dis_date,$s_date);
			push(@dis_city,$a_acity[$i]);
			$sql = "select City_name,Min_tmp,Max_tmp,Weather,Cloud from ctninfo..Weather where City_ID='$a_acity[$i]' and W_date='$s_date' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT) {
					while(@row = $db->ct_fetch) {
						if ($in{trip} eq '0') {
							print "<tr><td height=20 width=110>$d_name：</td><td width=60>$row[0]</td>
							<td width=60>$row[1]－$row[2]℃</td>
							<td width=100>$row[3]</td><td width=370>$row[4]</td></tr>";
						}
						else {
							$html_weather .= qq`
							<tr>
								<td width="115" class="nobr"><nobr>$d_name：</nobr></td>
								<td width="100">$row[0]</td>
								<td width="100">$row[1]－$row[2]℃</td>
								<td width="100">$row[3]</td>
								<td>$row[4]</td>
							</tr>`;
						}
						$find ++;	
					}
				}
			}
			if ($find == 0 && ($User_type eq "O" || $User_type eq "S")) {
				if ($in{trip} eq '0') {
					print "<tr><td height=20 width=110>$d_name：</td>
					<td colspan=5><font color=red>$cityname{$a_acity[$i]} <a href='/cgishell/client/air_other.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&OD=WF:$a_acity[$i]&dis=W' target=_wf title='查询天气预报'><font color=red>无当日天气信息</td>
					</tr>";
				}
				else {
					$html_weather .= qq`
					<tr>
						<td width="115" class="nobr"><nobr>$d_name：</nobr></td>
						<td colspan="5" style="color: red;">$cityname{$a_acity[$i]} <a href='/cgishell/client/air_other.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&OD=WF:$a_acity[$i]&dis=W' target="_wf" title='查询天气预报'><font color="red">无当日天气信息</a></td>
					</tr>`;
				}
			}
		}
	}
	if ($in{trip} eq '0') {
		print "</table>
		<img src='/images/border_bottom.gif'></td></tr>";
	}
	else {
		$html_weather .= "</table>";
	}

	## ---------------------------------------------------------------------
	## 退改签规定
	## ---------------------------------------------------------------------
	my $class_cmt = "";
	if ($in{classcmt} eq 'Y') {
		for ($i=0; $i<$air_num; $i++) {
			my $a_code = substr($a_flight[$i],0,2);		my $d_cls=$a_code.$a_class[$i];
			my $find = 0;
			for ($j=0;$j<scalar(@dis_class);$j++) {
				if ($dis_class[$j] eq $d_cls) {	## 相同城市，不再显示
					$find = 1;
				}
			}
			if ($find == 0) {
				push(@dis_class, $d_cls);
				$sql = "select rtrim(Return_ticket),rtrim(Comment) 
					from ctninfo..Class_agio 
					where Airline_code='$a_code' 
						and Class_code='$a_class[$i]' 
						and convert(char(10),Start_date,102) <= '$depart_date[$i]'
						and convert(char(10),End_date,102) > '$depart_date[$i]' 
						and ((Corp_ID='SKYECH' and Depart in ('ALL','$a_dcity[$i]') and Arrive in ('ALL','$a_acity[$i]')) or 
							((Corp_ID='$Corp_center') 
							and Depart='$a_dcity[$i]' 
							and Arrive in ('ALL','$a_acity[$i]')))
						and Status <> 'D'
						and (Is_share <>'Y' or Is_share=null) ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT) {
						while(@row = $db->ct_fetch) {	
							$class_cmt .= qq`<tr><td colspan="4">$a_name[$i] （$a_class[$i]舱）</td></tr>`;
							if (length($row[0]) < 50 &&  length($row[1]) < 50) {	
								$class_cmt .= qq`
								<tr valign="top">
									<td width="50" class="nobr"><b>退票：</b></td>
									<td width="300"><em id="classcmt1_$find" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[0]</em></td>
									<td width="50" class="nobr"><b>改签：</b></td>
									<td width="300"><em id="classcmt2_$find" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">$row[1]</em></td>
								</tr>`;
							}
							else{
								$class_cmt .= qq`
								<tr valign="top">
									<td width="50" class="nobr"><b>退票：</b></td>
									<td><em id="classcmt1_$find" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$row[0]</em></td>
								</tr>
								<tr valign="top">
									<td width="50" class="nobr"><b>改签：</b></td>
									<td><em id="classcmt2_$find" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$row[1]</em></td>
								</tr>`;
							}
							$find ++;	
						}
					}
				}
			}
		}
	}
	if ($class_cmt ne "") {
		if ($in{trip} eq '0') {
			$class_cmt = qq!<tr><td height=34><b>退改签规定：</b><br><img src='/images/border_top.gif'></td></tr>
				<tr><td align=center><table border=0 width=98% cellpadding=0 cellspacing=0>
				$class_cmt
				</table>
				</td></tr>
				<tr><td><img src='/images/border_bottom.gif'></td></tr>!;
		}
		else{
			$class_cmt = qq`
			<table border="0" cellspacing="0" cellpadding="0" class="tab5" id="caption5" onmouseover="Fid('caption5').id='caption5_tmp'; this.id='caption5'; showMenu(this.id, false, 1);">
				<caption>退改签规定：</caption>
				<tbody id="tab_content_5">
					$class_cmt
				</tbody>
			</table>`;
		}
	}

	## ---------------------------------------------------------------------
	## 特别提示
	## ---------------------------------------------------------------------
	my $html_tips = '';
	if ($in{trip} eq '0') {
		if ($in{classcmt} eq 'Y') {	 $class_cmt;	}
		print "<tr><td height=34><b>特别提示：</b><br><img src='/images/border_top.gif'></td></tr>
		<tr><td align=center><table border=0 width=98% cellpadding=0 cellspacing=0>";
	}
	else {
		$html_tips = '<table border="0" width="100%" cellpadding="0" cellspacing="0" class="tipinfo">';
	}
	if ($in{cb_c} ne "") {	## 出发城市大巴信息
		for ($i=0;$i<$air_num;$i++) {
			my $find = 0;
			for ($j=0;$j<scalar(@dis_bus);$j++) {
				if ($a_dcity[$i] eq $dis_bus[$j]) {	## 相同城市，不再显示
					$find = 1;
				}
			}
			if ($find == 0) {
				push(@dis_bus,$a_dcity[$i]);
				if ($in{trip} eq '0') {
					print "<tr><td colspan=2 height=20><b>$a_arrive[$i]大巴时刻表：</td></tr>";
				}
				else {
					$html_tips .= "<tr><td colspan=2><b>$a_depart[$i]大巴时刻表：</b></td></tr>";
				}
				$sql = "select Msg_title,Msg from ctninfo..City_msg 
					where City_ID='$a_dcity[$i]' and Msg_type='C' and Corp_ID in ('SKYECH','$Corp_center') 
					order by Msg_serial ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT) {
						while(@row = $db->ct_fetch) {
							$row[1] =~ s/\r\n/<br>/g;
							if ($in{trip} eq '0') {
								print "<tr><td valign=top width=70 height=20><b>$row[0]</b></td>
								<td valign=top>$row[1]</td></tr>";
							}
							else {
								$html_tips .= "<tr><td valign=top width=80 height=20><b>$row[0]</b></td>
									<td valign=top>$row[1]</td></tr>";
							}
							$find ++;
						}
					}
				}
				if ($find == 0) {
					if ($in{trip} eq '0') {
						print "<tr><td valign=top colspan=2 height=20><font color=red>没有相关信息</td></tr>";
					}
					else {
						$html_tips .= "<tr><td valign=top colspan=2 height=20><font color=red>没有相关信息</td></tr>";
					}
				}
			}
		}	
	}
	if ($in{cb_a} ne "") {	## 出发城市大巴信息
		for ($i=0;$i<$air_num;$i++) {
			my $find = 0;
			for ($j=0;$j<scalar(@dis_bus);$j++) {
				if ($a_acity[$i] eq $dis_bus[$j]) {	## 相同城市，不再显示
					$find = 1;
				}
			}
			if ($find == 0) {
				push(@dis_bus,$a_acity[$i]);
				if ($in{trip} eq '0') {
					print "<tr><td colspan=2 height=20><b>$a_arrive[$i]大巴时刻表：</td></tr>";
				}
				else {
					$html_tips .= qq`<tr><td colspan="2"><b>$a_arrive[$i]大巴时刻表：</b></td></tr>`;
				}
				$sql = "select Msg_title,Msg from ctninfo..City_msg 
					where City_ID='$a_acity[$i]' and Msg_type='C' and Corp_ID in ('SKYECH','$Corp_center') 
					order by Msg_serial ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT) {
						while(@row = $db->ct_fetch) {
							$row[1] =~ s/\r\n/<br>/g;
							if ($in{trip} eq '0') {
								print "<tr><td valign=top width=70 height=20><b>$row[0]</b></td>
								<td valign=top>$row[1]</td></tr>";
							}
							else {
								$html_tips .= qq`
									<tr valign="top">
										<td width="80"><b>$row[0]</b></td>
										<td>$row[1]</td>
									</tr>`;
							}
							$find ++;
						}
					}
				}
				if ($find == 0) {
					if ($in{trip} eq '0') {
						print "<tr><td valign=top colspan=2 height=20><font color=red>没有相关信息</td></tr>";
					}
					else {
						$html_tips .= "<tr><td valign=top colspan=2 height=20><font color=red>没有相关信息</td></tr>";
					}
				}
			}
		}	
	}

	for ($i=0;$i<$in{i_num};$i++) {
		my $cb = "cb_$i";
		if ($in{$cb} ne "") {
			my $info = "info_$i";
			if ($in{trip} eq '0') {
				print "<tr><td width=70 height=20><b>$in{$cb}</b></td>
				<td valign=top>$in{$info}</td></tr>";
			}
			else {
				$html_tips .= qq`
				<tr valign="top">
					<td width="70"><b>$in{$cb}</b></td>
					<td>$in{$info}</td>
				</tr>`;
			}
		}
	}

	if ($in{trip} eq '0') {
		print "</table>
		<img src='/images/border_bottom.gif'></td></tr>
		</table>";
		print $templatefooter;
		print qq!
		<SCRIPT LANGUAGE="JavaScript">
			document.title = "$corp_name-旅客行程单";
		</script></span>
		<table width=650 border=0 cellpadding=0 cellspacing=0>
		<tr bgcolor=f0f0f0>
		<td align=right height=22 colspan=4><img src='/admin/index/images/print.gif' align=absmiddle> <a href="javascript:goPrint()">打印行程单</a> <a href="$forward&trip=2">换样式三</a></td>
		</tr>
		</table>!;
	}
	else {
		$html_tips .= "</table>";
	}

	if ($in{trip} ne '0' && $in{trip} ne '1') {
		if ($templateheader eq '') {
			$templateheader = qq`<table border="0" cellspacing="0" cellpadding="0" class="tab1" id="caption1" onmouseover="Fid('caption1').id='caption1_tmp'; this.id='caption1'; showMenu(this.id, false, 1);">
						<tr id="tab_content_1">
							<td><em id="welcome" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$template</em></td>
							<td class="corplogo">$corp_logo</td>
						</tr>
					</table>`;
			$trip_title = qq`<h1 class="tcktitle tc" id="ticket_title_h1">机票行程提醒单</h1>
				<h2 class="tcktitle en" id="ticket_title_h2">ITINERARY</h2>`;
		}
		my %check_cb = ();
		if ($in{cb_a} eq 'A') {
			$check_cb{cba} = ' checked';
		}
		if ($in{cb_c} eq 'C') {
			$check_cb{cbc} = ' checked';
		}
		if ($in{print_logo} eq 'Y') {
			$check_cb{logo} = ' checked';
		}
		if ($in{classcmt} eq 'Y') {
			$check_cb{cmt} = ' checked';
		}
		
		my $body_width=($in{trip} eq '7')?"800":"700";
		print qq`
		<style type="text/css" media="print">
		/* media="print" 这个属性可以在打印时有效 */
		/* 不打印 */
		.Noprint{ display: none; }
		/* 分页 */
		.PageNext{ page-break-after: always; }
		</style>
		<style type="text/css" media="screen">
		.wrapper {
			background: #f4f4f4;
		}
		.operation {
			margin: 15px auto;
			text-align: center;
			background: #FFFAD8;
			border: #FFD35D solid 1px;
		}
		.operation button {
			margin: 1px;
			width: 75px;
			cursor: pointer;
			padding: 0;
		}
		.group { width: 100%; padding: 1px; }
		.grouparea { width: 100%; height: 100px; vertical-align: top; }
		.editor { background: $editorColor; }
		#showOrderAlert { width: 656px; position: absolute; left: 10px; top: 10%; z-index: 101; background: #fff; border: #ff6600 solid 2px; padding: 30px 20px; }
		.operation_menu { display: block; margin-left: 850px; width: 80px; border: #cae1ff solid 1px; text-align: center; }
		.operation_menu li, .operation_menu li a { display: block; clear: both; zoom: 1; }
		.operation_menu li a { padding: 5px; }
		.operation_menu li a:link, .operation_menu li a:visited { text-decoration: none; color: #666; }
		.operation_menu li a:hover { background: #f4fbff; color: #090 }
		</style>
		<style type="text/css" media="all">
		body { font-size: 12px; margin: 0px; }
		h1, h2, ul, li { margin: 0; padding: 0; }
		ul, li { list-style: none; }
		em {
			font-style: normal;
			font-family: Geneva, Helvetica;
		}
		strong { font-family: 黑体; font-weight: normal; font-size: 12px; }
		.nobr, .nobr * { white-space: nowrap; }
		.content { border: #000 solid 0px; /*height: 700px;*/ }
		.tcktitle {
			width: 100%;
			overflow: hidden;
		}
		h1 {
			text-align: center;
			font-family: 黑体;
			font-size: 25px;
			font-weight: normal;
		}
		h2 {
			text-align: center;
			font-size: 20px;
			margin-bottom: 8px;
		}
		.tips { padding: 3px; text-align: left; font-size: 12px; color: #ff0000; }
		caption { border: 0; padding: 3px; text-align: left; font-size: 16px; font-family: 黑体; border-bottom: #666 solid 1px; }
		.tab1, .tab2, .tab3, .tab4, .tab5 { width: 100%; border-collapse: collapse; font-size: 14px; }
		.tab1, .tab3 { text-align: left; padding: 8px; }
		.tab1 li, .tab3 li { padding: 3px 0; }
		.tab2, .tab5 { margin-top: 15px; }
		.tab2 th { padding: 8px; text-align: left; font-family: 黑体; font-weight: normal; }
		.tab2 td, .tab2 th, .tab5 td { padding: 2px; }
		.tab3 { margin-top: 20px; }
		.row1 th, .row1 td { border-bottom: #666 solid 1px; }
		.corplogo { width: 200px; text-align: right; }
		.tripbox { border-bottom: #666 solid 1px; }
		.person td { padding: 0; }
		.tipinfo td { padding: 3px 0; line-height: 130%; }
		</style>
		<script type="text/javascript">
		function gourl() {
			var param = '';
			for (var i = 0; i < 4; i++) {
				if (document.getElementById('CP_' + i).checked) {
					var key = document.getElementById('CP_' + i).name;
					var value = document.getElementById('CP_' + i).value;
					param += '&' + key + '=' + value;
				}
			}
			window.location.href = '?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&trip=$in{trip}&resid=$in{resid}&relate_num=$in{relate_num}' + param;
		}
		</script>
		</head>
		<body onKeyDown="ctrlMove();" onload="init()">
		<div id="layerbox" style="z-index: 100; left: 10px; top: 0px; width: $body_width\px; position: absolute;">
			<div id="layOutDiv"></div>`;
			if ($in{trip} eq '5') {#样式六 电子客票行程单 每个乘客一张行程单 fanzy@2014-04-08
				my $tempLast_name="";
				my @tempdata=();
				$sql = "select rtrim(a.Reservation_ID),rtrim(a.Booking_ref),convert(char(11),convert(date,a.Ticket_time),106),a.Office_ID,a.Pay_method,a.Agent_ID,
					b.Last_name,b.Res_serial,b.First_name,b.Card_ID,b.Air_code,b.Seat_type,b.Out_price,b.Tax_fee,b.YQ_fee,
					c.Departure,c.Arrival,convert(char(11),convert(date,c.Air_date),106),c.Airline_ID,c.Flight_no,c.Depart_time,c.Arrive_time,c.Duration,
					d.City_cname,d.City_name,d.Airport_cname,d.Time_diff,e.City_cname,e.City_name,e.Airport_cname,e.Time_diff,
					f.Airline_cname,f.Airline_name,f.Airline_logo,g.Corp_csname,g.Tel,g.Fax,g.Address,rtrim(c.IsReturn),b.Ticket_ID,b.In_price,b.Origin_price,b.Tax_fee,b.YQ_fee,b.Other_fee,isnull(b.Service_fee,0)
						FROM ctninfo..Airbook_$Top_corp a,
							ctninfo..Airbook_detail_$Top_corp b,
							ctninfo..Airbook_lines_$Top_corp c,
							ctninfo..IATA_city d,
							ctninfo..IATA_city e,
							ctninfo..Airlines f,
							ctninfo..Corp_info g
						WHERE a.Reservation_ID = b.Reservation_ID
							and a.Reservation_ID = c.Reservation_ID
							and b.Res_serial = c.Res_serial
							and c.Departure = d.IATA_ID 
							and c.Arrival = e.IATA_ID
							and c.Airline_ID = f.Airline_code 
							and a.Agent_ID = g.Corp_ID 
					and a.Reservation_ID = '$a_resid[$i]'
						order by b.Last_name,b.Res_serial " ;
				if ($sqlbook ne "") {
					$sql = "$sqlbook \n $sqllines \n $sqldetail
					select rtrim(a.Reservation_ID),rtrim(a.Booking_ref),convert(char(11),convert(date,a.Ticket_time),106),a.Office_ID,a.Pay_method,a.Agent_ID,
					b.Last_name,b.Res_serial,b.First_name,b.Card_ID,b.Air_code,c.Seat_type,b.Out_price,b.Tax_fee,b.YQ_fee,
					c.Departure,c.Arrival,convert(char(11),convert(date,c.Air_date),106),c.Airline_ID,c.Flight_no,c.Depart_time,c.Arrive_time,c.Duration,
					d.City_cname,d.City_name,d.Airport_cname,d.Time_diff,e.City_cname,e.City_name,e.Airport_cname,e.Time_diff,
					f.Airline_cname,f.Airline_name,f.Airline_logo,g.Corp_csname,g.Tel,g.Fax,g.Address,rtrim(c.IsReturn),b.Ticket_ID,b.In_price,b.Out_price,b.Tax_fee,b.YQ_fee,b.Other_fee,isnull(b.Service_fee,0)
						FROM #tempAirbook a,
							#tempAirbookdetail b,
							#tempAirbooklines c,
							ctninfo..IATA_city d,
							ctninfo..IATA_city e,
							ctninfo..Airlines f,
							ctninfo..Corp_info g
						WHERE a.Reservation_ID = b.Reservation_ID
							and a.Reservation_ID = c.Reservation_ID
							and b.Res_serial = c.Res_serial
							and c.Departure = d.IATA_ID 
							and c.Arrival = e.IATA_ID
							and c.Airline_ID = f.Airline_code 
							and a.Agent_ID = g.Corp_ID 
						order by b.Last_name,b.Res_serial
					drop table #tempAirbook
					drop table #tempAirbooklines
					drop table #tempAirbookdetail " ;
				}
				#print "<pre>$sql";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT) {
						while(@row = $db->ct_fetch) {
							push(@tempdata,[@row]);
						}
					}
				}
				my $temp_k=0;
				for (my $k=0;$k<scalar(@tempdata) ;$k++) {
					my @row=@{$tempdata[$k]};
						if ($tempLast_name ne $row[6]) {
							my $Ticket_time=airdate_format($row[2]);
							my $CATA="";
							$row[3]="CAN196";
							if ($row[3] ne "") {
								$sql = "select Office_ID,rtrim(BSP)
										from ctninfo..Office_info 
										where (Corp_ID='$Corp_center' or User_ID='$in{User_ID}')
											and Is_insure='Y'
											and Office_ID='$row[3]' ";
								$db->ct_execute($sql);
								while($db->ct_results($restype) == CS_SUCCEED) {
									if($restype==CS_ROW_RESULT)	{
										while(@rows = $db->ct_fetch)	{
											$CATA=$rows[1];
										}
									}
								}
							}
							my $tk_id = "";
							if ($row[39] > 0) {
								$tk_id = "$row[10]-$row[39]";
							}
							if ($tk_id eq '') {
								$tk_id = '__';
							}
							print qq`
							<div class="wrapper">
								<div class="corplogo" style='text-align:left;'>$corp_logo</div>
								<hr style="border-top:1px #666; height:1px;width:99%;">
								<h1 class="tcktitle tc" id="ticket_title_h1">电子客票行程单</h1>
								<div class="content">
									<table border="0" cellspacing="0" cellpadding="0" class="tab2" id="caption2"
									onmouseover="Fid('caption2').id='caption2_tmp'; this.id='caption2'; showMenu(this.id, false, 1);">
										<tr id="tab_content_2">
											<td>
												<table border="0" cellspacing="0" cellpadding="0" width="100%" class="tripbox">
													<tr>
														<td style="text-align:right"><nobr>航空公司记录编号：</nobr></td>
														<td><nobr>$row[1]</nobr></td>
														<td style="text-align:right"><nobr>订座记录编号：</nobr></td>
														<td><nobr>$row[1]</nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>旅客姓名：</nobr></td>
														<td><nobr>$row[8]</nobr></td>
														<td style="text-align:right"><nobr>票号：</nobr></td>
														<td><nobr>$tk_id</nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>身份识别代码：</nobr></td>
														<td><nobr>$row[9]</nobr></td>
														<td style="text-align:right"><nobr>联票：</nobr></td>
														<td><nobr></nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>出票航空公司：</nobr></td>
														<td><nobr>$row[31]</nobr></td>
														<td style="text-align:right"><nobr>出票时间：</nobr></td>
														<td><nobr>$Ticket_time</nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>出票代理人：</nobr></td>
														<td><nobr>$row[34]</nobr></td>
														<td style="text-align:right"><nobr>航协代码：</nobr></td>
														<td><nobr>$CATA</nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>代理人地址：</nobr></td>
														<td colspan=3><nobr>$row[37]</nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>电话：</nobr></td>
														<td><nobr>$row[35]</nobr></td>
														<td style="text-align:right"><nobr>传真：</nobr></td>
														<td><nobr>$row[36]</nobr></td>
													</tr>
												</table>
												<table border="0" cellspacing="0" cellpadding="0" width="100%" class="tripbox">
													<tr>
														<td colspan="5">
															<table border="0" cellpadding="0" cellspacing="0" width="100%" class="person">
																<tr style="text-align: center;">
																	<td rowspan=2 class="tripbox"><nobr>始发地/目的地</nobr></td>
																	<td rowspan=2 class="tripbox"><nobr>航班</nobr></td>
																	<td rowspan=2 class="tripbox"><nobr>座位等级</nobr></td>
																	<td rowspan=2 class="tripbox"><nobr>日期</nobr></td>
																	<td rowspan=2 class="tripbox"><nobr>起飞时间</nobr></td>
																	<td rowspan=2 class="tripbox"><nobr>到达时间</nobr></td>
																	<td rowspan=2 class="tripbox"><nobr>有效期</nobr></td>
																	<td rowspan=2 class="tripbox"><nobr>客票状态</nobr></td>
																	<td rowspan=2 class="tripbox"><nobr>行李</nobr></td>
																	<td colspan=2><nobr>航站楼</nobr></td>
																</tr>
																<tr style="text-align: center;">
																	<td class="tripbox"><nobr>起飞</nobr></td>
																	<td class="tripbox"><nobr>到达</nobr></td>
																</tr>`;
							$tempLast_name=$row[6];
							$Origin_price=0;$Tax_fee=0;$YQ_fee=0;$Other_fee=0;$Service_fee=0;
						}
																my $Air_date=substr(airdate_format($row[17]),0,5);
																##显示航站楼 dingwz@2014-07-31
																my ($d_port,$a_port) = split(',',$row[38]);
																$d_port =~ s/^\s+|\s+$//g;$a_port =~ s/^\s+|\s+$//g;
																if ($d_port ne "") {
																	##$d_port="<font color=red style='font-size:8pt'>T$d_port</font>";
																	$d_port="$d_port号航站楼";
																}
																if ($a_port ne "") {	
																	##$a_port="<font color=red style='font-size:8pt'>T$a_port</font>";
																	$a_port="$a_port号航站楼";
																}
																print qq`
																<tr style="text-align: center;height:32px;">
																	<td><nobr>$row[23]$row[27]</nobr></td>
																	<td><nobr>$row[18]$row[19]</nobr></td>
																	<td><nobr>$row[11]</nobr></td>
																	<td><nobr>$Air_date</nobr></td>
																	<td><nobr>$row[20]</nobr></td>
																	<td><nobr>$row[21]</nobr></td>
																	<td><nobr> </nobr></td>
																	<td><nobr>$row[22]</nobr></td>
																	<td><nobr>20K</nobr></td>
																	<td><nobr>$d_port</nobr> </td>
																	<td><nobr>$a_port</nobr></td>
																</tr>`;
						my @rowtemp=@{$tempdata[$k+1]};
						if ($fare_calculation ne "") {$fare_calculation.="<br>";}
						$fare_calculation.=airdate_format($row[17])."$row[15] $row[18] $row[16]$row[40]CNY$row[40]END";
						$Origin_price+=sprintf("%.2f",$row[41]);
						$Tax_fee+=sprintf("%.2f",$row[42]);
						$YQ_fee+=sprintf("%.2f",$row[43]);
						$Other_fee+=sprintf("%.2f",$row[44]);
						$Service_fee+=sprintf("%.2f",$row[45]);
						if ($rowtemp[6] ne $row[6]) {
															$rental=sprintf("%.2f",($Origin_price+$Tax_fee+$YQ_fee+$Other_fee+$Service_fee));
															print qq`
															</table>
														</td>
													</tr>
												</table>
												<table border="0" cellpadding="0" cellspacing="0" width="100%" class="person" style="margin-top:8px;$price_nshows">
													<tr>
														<td style="text-align:right"><nobr>票价计算：</nobr></td>
														<td colspan=2>$fare_calculation</td>
													</tr>
													<tr>
														<td style="text-align:right" rowspan=3><nobr>付款方式：</nobr></td>
														<td rowspan=3><nobr>$row[4]</nobr></td>
														<td style="text-align:right" rowspan=3><nobr>税款：</nobr></td>
														<td><nobr><em id="tkpricea_m$temp_k" class="editor" title="机建费 点击修改此内容" onclick="insertText(this, 1);">CNY$Tax_fee</em></nobr></td>
													</tr>
													<tr>
														<td><nobr><em id="tkpriceb_m$temp_k" class="editor" title="燃油费 点击修改此内容" onclick="insertText(this, 1);">CNY$YQ_fee</em></nobr></td>
													</tr>
													<tr>
														<td><nobr><em id="tkpricec_m$temp_k" class="editor" title="其它 点击修改此内容" onclick="insertText(this, 1);">CNY$Other_fee</em></nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>服务费：</nobr></td>
														<td><nobr><em id="tkpricec_m$temp_k" class="editor" title="服务费 点击修改此内容" onclick="insertText(this, 1);">CNY$Service_fee</em></nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>机票款：</nobr></td>
														<td colspan=3><nobr><em id="tkpriced_m$temp_k" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">CNY$Origin_price</em></nobr></td>
													</tr>
													<tr>
														<td style="text-align:right"><nobr>总 额：</nobr></td>
														<td colspan=3><nobr><em id="tkpricee_m$temp_k" class="editor" title="点击修改此内容" onclick="insertText(this, 1);">CNY$rental</em></nobr></td>
													</tr>
												</table>
											</td>
										</tr>
									</table>
								</div>
							</div>
							<hr style="border-top:1px dashed #cccccc; height:1px">`;
							$fare_calculation="";$temp_k++;
						}
				}
			}elsif($in{trip} eq '7'){#退废单退票办理单
				## 查询配置信息 
				my $Air_parm;
				my $Logo_url;
				$sql = "select Air_parm,rtrim(Trip_logo) from ctninfo..Corp_extra where Corp_ID='$Corp_center' ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							($Air_parm,$Logo_url)=@row;
						}
					}
				}
				
				$html_scheduling="";
				$sql = "select rtrim(a.Reservation_ID),rtrim(a.Booking_ref),a.User_ID,g.Corp_csname,convert(char(10),convert(date,a.Ticket_time),102),
				b.Air_code,b.Ticket_ID,b.Ticket_LID,b.First_name,b.Is_ET,d.City_cname,e.City_cname,c.Airline_ID,c.Flight_no,b.Seat_type,
				convert(char(10),c.Air_date,102),c.Depart_time,'',b.Tax_fee,a.Delivery_method,f.Corp_csname,a.Contact,a.Userbp,
				convert(char(10),convert(date,a.S_date),102),a.S_time,a.Book_ID,a.Comment,b.YQ_fee,b.Insure_outprice*b.Insure_num,a.Abook_method,
				a.Pay_method,a.Recv_total,b.Out_price,b.Origin_price,a.AAboook_method,a.Alert_status,a.Old_resid,b.Return_price,c.Departure,c.Arrival,
				b.Card_ID,b.Passage_type,b.Service_fee,b.Other_fee,rtrim(a.Office_ID) 
						FROM ctninfo..Airbook_$Top_corp a,
							ctninfo..Airbook_detail_$Top_corp b,
							ctninfo..Airbook_lines_$Top_corp c,
							ctninfo..IATA_city d,
							ctninfo..IATA_city e,
							ctninfo..Corp_info g,
							ctninfo..Corp_info f
						WHERE a.Reservation_ID = b.Reservation_ID
							and a.Reservation_ID = c.Reservation_ID
							and b.Res_serial = c.Res_serial
							and c.Departure = d.IATA_ID 
							and c.Arrival = e.IATA_ID
							and a.Corp_ID = g.Corp_ID 
							and a.Agent_ID = f.Corp_ID 
							and a.Reservation_ID = '$a_resid[$i]'
						order by b.Res_serial,b.Last_name " ;
				#print "<pre>$sql";exit;
				my $xi=0;
				my $f_refund_total=0;my $f_insure_total=0;my $f_receivable_total=0;
				my @tempdata=();
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT) {
						while(@row = $db->ct_fetch) {
							push(@tempdata,[@row]);
							$f_Old_resid=$row[36];
						}
					}
				}
				if ($f_Old_resid ne "") {
					$sql = "select Book_status,Agt_total+Insure_out+Other_fee+isnull(Service_fee,0)-Recv_total,APay_method,Alert_status,Tag_str,If_out,AAboook_method
							FROM ctninfo..Airbook_$Top_corp
							WHERE Reservation_ID = '$f_Old_resid' " ;
					#print "<pre>$sql";exit;
					$db->ct_execute($sql);
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT) {
							while(@row = $db->ct_fetch) {
								$old_status=&cv_airstatus($row[0],"S",$row[1],$row[2],$row[3],$row[4],$row[5],$row[6]);
							}
						}
					}
				$sql = "select b.First_name,rtrim(c.Airline_ID+c.Flight_no),c.Departure,c.Arrival,b.Ticket_ID,b.Card_ID,b.Passage_type,b.Out_price
						FROM ctninfo..Airbook_$Top_corp a,
							ctninfo..Airbook_detail_$Top_corp b,
							ctninfo..Airbook_lines_$Top_corp c
						WHERE a.Reservation_ID = b.Reservation_ID
							and a.Reservation_ID = c.Reservation_ID
							and b.Res_serial = c.Res_serial
							and a.Reservation_ID = '$f_Old_resid'
						order by b.Res_serial,b.Last_name ";
					#print "<pre>$sql";exit;
					$db->ct_execute($sql);
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT) {
							while(@row = $db->ct_fetch) {
								##姓名+航班号+出发抵达+票号+证件号码+乘客类型
								my $old_key=$row[0].$row[1].$row[2].$row[3].$row[4].$row[5].$row[6];
								$out_price_oldres{$old_key}=$row[7];
							}
						}
					}
				}
				my $recv_total=0;
				my $approver;
				$sql = "select Operator from ctninfo..Res_op where Reservation_ID='$a_resid[$i]' and Res_type='A' and Operate_type='o' having Operate_time=max(Operate_time) ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							$approver=@row[0];
						}
					}
				}
				my %office_hash = &get_office($Corp_office,"","hash","A");
				for (my $k=0;$k<scalar(@tempdata) ;$k++) {
					my @row=@{$tempdata[$k]};
					$f_resid=$row[0];$f_pnr=$row[1];$f_userid=$row[2];$f_corpname=$row[3];$f_tickettime=$row[4];
					$f_ticketid=($row[7] ne "" && $row[7] ne "0")?$row[5].'-'.$row[6].'^'.$row[7]:$row[5].'-'.$row[6];
					$f_delivery=$row[19];$f_agentname=$row[20];$f_contact=$row[21];$f_userbp=$row[22];
					if($f_userbp=~/[A-Z]$/){ $f_userbp=&JieMi_ph($f_userbp); }
					$f_sdate=$row[23]." ".substr($row[24],0,2).":".substr($row[24],2);
					$f_departure_time=$row[15]." ".substr($row[16],0,2).":".substr($row[16],2);
					$f_bookid=$row[25];$book_method=$row[29];$pay_method=$row[28];$recv_total+=$row[32];
					$comm_method=$row[34];$is_refund=$row[35];$f_Old_resid=$row[36];
					$f_comment=$row[26];
					if (($Corp_type eq "T" || $Is_delivery eq "Y") && $is_refund=~/[0,3,4]/ && $comm_method eq "C"  && $Air_parm=~/C/) {
						$print_comm="U";
					}
					$row[12]=~ s/\s*//g;$row[13]=~ s/\s*//g;
					my $old_key=$row[8].$row[12].$row[13].$row[38].$row[39].$row[6].$row[40].$row[41]; 
					$office_info=($office_hash{$row[44]} ne '')?$office_hash{$row[44]}:$row[44];
					$old_ticket_price=sprintf("%.2f",$out_price_oldres{$old_key});
					$f_ticket_price=sprintf("%.2f",$row[32]);
					$f_tax_fee=sprintf("%.2f",$row[18]);
					$f_Service_fee=sprintf("%.2f",$row[42]);
					$f_Other_fee=sprintf("%.2f",$row[43]);
					$f_editor=sprintf("%.2f",$row[27]);
					$f_insure=sprintf("%.2f",$row[28]);
					$f_refund_price=sprintf("%.2f",$row[37]);
					$f_receivable=sprintf("%.2f",$f_ticket_price+$f_tax_fee+$f_editor+$f_insure+$f_Service_fee+$f_Other_fee);
					$f_refund_total=$f_refund_total+$f_refund_price;
					$f_insure_total=$f_insure_total+$f_insure;
					$f_receivable_total=$f_receivable_total+$f_receivable;
					$cc_comm=sprintf("%.2f",$row[32]-$row[33]);
					if ($comm_method eq "N") {
						$cc_comm=0;
					}
					$cc_comm =~ s/\s*\.00//;
					$html_scheduling{$xi}.=qq`
					<tr>
						<td><nobr>$f_ticketid</nobr></td>
						<td><nobr>$row[8]</nobr></td>
						<td><nobr>$row[9]</nobr></td>
						<td><nobr>$row[10]-$row[11]</nobr></td>
						<td><nobr>$row[12]$row[13]</nobr></td>
						<td style="text-align: center;"><nobr>$row[14]</nobr></td>
						<td><nobr>$f_departure_time</nobr></td>
						<td style="text-align: right;$price_nshows"><nobr><em id="ticket_price_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$old_ticket_price</em></nobr></td>
						<td style="text-align: right;$price_nshows"><nobr><em id="cc_comm_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$cc_comm</em></nobr></td>
						<td style="text-align: right;$price_nshows"><nobr><em id="Tax_fee_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_tax_fee</em>/<em id="Taxes_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_editor</em>/<em id="insure_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_insure</em></nobr></td>
						<td style="text-align: right;$price_nshows"><nobr><em id="refund_price_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_refund_price</em></nobr></td>
						<td style="text-align: right;$price_nshows"><nobr><em id="Service_fee_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_Service_fee</em></nobr></td>
						<td style="text-align: right;$price_nshows"><nobr><em id="Other_fee_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_Other_fee</em></nobr></td>
						<td style="text-align: right;$price_nshows"><nobr><em id="receivable_$xi" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_receivable</em></nobr></td>
					</tr>`;
					$xi++;
				}
				$f_refund_total=sprintf("%.2f",$f_refund_total);
				$f_insure_total=sprintf("%.2f",$f_insure_total);
				$f_receivable_total=sprintf("%.2f",$f_receivable_total);
				my %pay=&get_dict($Corp_center,4,"","hash2");
				my $pay_name .= "$pay{$book_method}[1]";
				if ($pay_method ne "N" && $recv_total >0) {
					$recv_total =~ s/\s*\.00//;
					$pay_name .= "[已收$recv_total]";	 
				}
				my %Delivery_name=('S'=>"安排上门办理",'J'=>"机场柜台办理",'Q'=>"客人前台办理",'M'=>"邮寄发票",'N'=>"不需要收回行程单");
				push(@userlist,$in{User_ID});
				push(@userlist,$pay_user);
				push(@userlist,$dev_user);
				push(@userlist,$f_bookid);
				push(@userlist,$approver);
				my $userlist=join("','",@userlist);
				if ($userlist ne "") {
					$sql_t="select User_ID,User_name from ctninfo..User_info_op where Corp_num='$Corp_center' and User_ID in('$userlist') \n";
					$db->ct_execute($sql_t);
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT)	{
							while(@row = $db->ct_fetch)	{
								$user_name{$row[0]}=$row[1];
							}
						}
					}
				}
				
				my $page=int $xi/5;
				if ($xi%5>0) {
					$page++;
				}
				for ($i=0;$i<$page ;$i++) {
					$page_num=$i+1;
					$html_scheduling= qq`
					<table border="0" cellspacing="0" cellpadding="0" width="100%" class="tripbox">
						<tr style="text-align: left;">
							<td style="width:9%;"><nobr>客户名称：</nobr></td>
							<td style="width:22%;"><nobr>$f_corpname</nobr></td>
							<td style="width:5%;"><nobr>PNR：</nobr></td>
							<td style="width:8%;"><nobr>$f_pnr</nobr></td>
							<td style="width:9%;"><nobr>会员卡号：</nobr></td>
							<td style="width:18%;"><nobr>$f_userid</nobr></td>
							<td style="width:9%;"><nobr>订座单号：</nobr></td>
							<td style="width:20%;"><nobr>$f_resid</nobr></td>
						</tr>
					</table>
					<table border="0" cellspacing="0" cellpadding="0" width="100%" class="tripbox">
						<tr style="text-align: left;">
							<td style="width:9%;"><nobr>经办部门：</nobr></td>
							<td style="width:16%;"><nobr>$f_agentname</nobr></td>
							<td style="width:9%;"><nobr>联 系 人：</nobr></td>
							<td style="width:16%;"><nobr>$f_contact</nobr></td>
							<td style="width:9%;"><nobr>联系电话：</nobr></td>
							<td style="width:16%;"><nobr>$f_userbp</nobr></td>
							<td style="width:9%;"><nobr>办理时间：</nobr></td>
							<td style="width:16%;"><nobr>$f_sdate</nobr></td>
						</tr>
						<tr style="text-align: left;">
							<td><nobr>经 办 人：</nobr></td>
							<td><nobr>$f_bookid $user_name{$f_bookid}</nobr></td>
							<td><nobr>办理方式：</nobr></td>
							<td><nobr>$Delivery_name{$f_delivery}</nobr></td>
							<td><nobr>票证来源: </nobr></td>
							<td><nobr>$office_info</nobr></td>
							<td><nobr>批准人: </nobr></td>
							<td><nobr>$approver $user_name{$approver}</nobr></td>
						</tr>
					</table>
					<table border="0" cellspacing="0" cellpadding="0" width="100%" class="tripbox" style="border-bottom-width:0px;">
						<tr style="text-align: left;">
							<td style="width:9%;"><nobr>出票时间：</nobr></td>
							<td style="width:16%;"><nobr>$f_tickettime</nobr></td>
							<td style="width:11%;"><nobr>正常票状态：</nobr></td>
							<td style="width:14%;"><nobr>$old_status</nobr></td>
							<td style="width:9%;"><nobr>配送备注：</nobr></td>
							<td style="width:41%;"><nobr>$f_comment</nobr></td>
						</tr>
					</table>
					<table border="1" cellspacing="0" cellpadding="0" width="100%" class="tripbox" style="border-style:solid;border-width:1px;border-color:#666;">
						<tr style="text-align: center;">
							<td><nobr>票号</nobr></td>
							<td><nobr>乘机人</nobr></td>
							<td><nobr>票证<br>类型</nobr></td>
							<td><nobr>航程</nobr></td>
							<td><nobr>航班</nobr></td>
							<td><nobr>舱<br>位</nobr></td>
							<td><nobr>起飞时间</nobr></td>
							<td$price_nshow><nobr>票价</nobr></td>
							<td$price_nshow><nobr>返佣</nobr></td>
							<td$price_nshow><nobr>基建/税费/保险</nobr></td>
							<td$price_nshow><nobr>应收<br>退票费</nobr></td>
							<td$price_nshow><nobr>退服务费</nobr></td>
							<td$price_nshow><nobr>其他</nobr></td>
							<td$price_nshow><nobr>应收<br>合计</nobr></td>
						</tr>`;
					for ($j=$i*5;$j<$i*5+5 ;$j++) {
						$html_scheduling.=$html_scheduling{$j};
					}
					$html_scheduling.=qq`</table>
					<table border="0" cellspacing="0" cellpadding="0" width="100%" class="tripbox"$price_nshow>
						<tr>
							<td style="width:9%;"><nobr>退款科目：</nobr></td>
							<td style="width:16%;"><nobr>$pay_name</nobr></td>
							<td style="width:11%;"><nobr>应收退票费：</nobr></td>
							<td style="width:14%;"><nobr>￥<em id="ticket_price" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_refund_total</em></nobr></td>
							<td style="width:9%;"><nobr>应退保险：</nobr></td>
							<td style="width:16%;"><nobr>￥<em id="refund_insure" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_insure_total</em></nobr></td>
							<td style="width:9%;"><nobr>应收合计：</nobr></td>
							<td style="width:16%;"><nobr>￥<em id="receivable_total" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$f_receivable_total</em></nobr></td>
						</tr>
					</table>
					<table border="0" cellspacing="0" cellpadding="0" width="100%" class="person">
						<tr>
							<td style="width:9%;"><nobr>打印时间：</nobr></td>
							<td style="width:20%;"><nobr>$getdate</nobr></td>
							<td style="width:8%;"><nobr>打印人：</nobr></td>
							<td style="width:16%;"><nobr>$in{User_ID} $user_name{$in{User_ID}}</nobr></td>
							<td style="width:8%;"><nobr>送票员：$dev_user $user_name{$dev_user}</nobr></td>
							<td style="width:16%;"><nobr></nobr></td>
							<td style="width:8%;"><nobr>收银员：$pay_user $user_name{$pay_user}</nobr></td>
							<td style="width:15%;"><nobr></nobr></td>
						</tr>
					</table>
					<div style="text-align: right;"><b>机票无误，请签名：＿＿＿＿＿＿</b></div>`;
					print qq`
					<div style="hight:2800px; padding-top:65px; padding-bottom:65px;">
						<div class="wrapper" style="width:900px; hight:40%;">
							<h1 class="tcktitle tc" id="ticket_title_h1">退废单退票办理单</h1><h2 class="tcktitle en" style="font-size:12px;">总页号:第 $page_num 页/共 $page 页</h2>
							<div class="content">
								<table border="0" cellspacing="0" cellpadding="0" class="tab2" id="caption2" onmouseover="Fid('caption2').id='caption2_tmp'; this.id='caption2'; showMenu(this.id, false, 1);">
									<tr id="tab_content_2">
										<td style="line-height: 21px;">
											$html_scheduling
										</td>
									</tr>
								</table>
								$class_cmt
							</div>
							$templatefooter
						</div>
					</div>`;
				}
			}else{
				print qq`
				<div class="wrapper">
					$trip_title
					<div class="content">
						$templateheader
						<table border="0" cellspacing="0" cellpadding="0" class="tab2" id="caption2" onmouseover="Fid('caption2').id='caption2_tmp'; this.id='caption2'; showMenu(this.id, false, 1);">
							<caption>航班信息：</caption>
							<tr id="tab_content_2">
								<td>
									$html_scheduling
								</td>
							</tr>
						</table>
						$class_cmt
						<table border="0" cellspacing="0" cellpadding="0" class="tab3" id="caption3" onmouseover="Fid('caption3').id='caption3_tmp'; this.id='caption3'; showMenu(this.id, false, 1);">
							<caption>天气预报：</caption>
							<tr id="tab_content_3">
								<td>
									$html_weather
								</td>
							</tr>
						</table>
						<table border="0" cellspacing="0" cellpadding="0" class="tab4" id="caption4" onmouseover="Fid('caption4').id='caption4_tmp'; this.id='caption4'; showMenu(this.id, false, 1);">
							<caption>特别提示：</caption>
							<tr id="tab_content_4">
								<td>
									$html_tips
								</td>
							</tr>
						</table>
					</div>
					<table border="0" cellspacing="0" cellpadding="0" class="tab4" id="caption6" onmouseover="Fid('caption6').id='caption6_tmp'; this.id='caption6'; showMenu(this.id, false, 1);">
						<tr id="tab_content_6">
							<td width="50">备注：</td>
							<td><em id="fare" class="editor" title="点击修改此内容" onclick="insertText(this, 2);">$comment</em></td>
						</tr>
					</table>
					$templatefooter
				</div>`;
			}
			print qq`
			<div class="operation Noprint">
				<table border="0" cellspacing="0" cellpadding="0" width="100%">
					<tr>
						<td>
							<button onclick="moveItem(0,-4);">上 移 ↑</button><br>
							<button onclick="moveItem(-4,0);">左 移 ←</button>
							<button onclick="moveItem(0,4);">下 移 ↓</button>
							<button onclick="moveItem(4,0);">右 移 →</button>
							<div style="text-align:left;"><input type="checkbox" name="cb_c" id="CP_0" value="C" onclick="gourl()"$check_cb{cbc} />机场大巴(出发)
								<input type="checkbox" name="print_logo" id="CP_1" value="Y" onclick="gourl()"$check_cb{logo} />公司标志</div>
							<div style="text-align:left;">
								<input type="checkbox" name="cb_a" id="CP_2" value="A" onclick="gourl()"$check_cb{cba} />机场大巴(抵达)
								<input type="checkbox" name="classcmt" id="CP_3" value="Y" onclick="gourl()"$check_cb{cmt} />退改签规定
							</div>
						</td>
						<td width="400">
							<div class="tips">提　示：请先把浏览器“打印设置”的边距均调为0。<br />　　　　灰色背景为打印部分，您可以使用键盘方向键进行微调！<br />　　　　蓝色背景的文字可点击修改。<br />　　　　关闭浏览器后需要重新设置打印边距。</div>
							<div class="tips" id="showmargin">左边距：10px<br />上边距：0px</div>
						</td>
						<td><button onclick="printInv()">直接打印</button><br /><button onclick="window.location.href='$forward&trip=0'">换样式一</button></td>
					</tr>
				</table>
				<iframe frameborder="0" id="frm_update" width="0" style="display: none;"></iframe>
			</div>
		</div>
		<ul class="operation_menu Noprint" id="caption1_menu" style="display: none;">
			<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_1'));">+ 放大字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_1'));">- 缩小字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_1'));">x 恢复默认</a></li>
		</ul>
		<ul class="operation_menu Noprint" id="caption2_menu" style="display: none;">
			<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_2'));">+ 放大字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_2'));">- 缩小字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_2'));">x 恢复默认</a></li>
		</ul>
		<ul class="operation_menu Noprint" id="caption3_menu" style="display: none;">
			<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_3'));">+ 放大字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_3'));">- 缩小字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_3'));">x 恢复默认</a></li>
		</ul>
		<ul class="operation_menu Noprint" id="caption4_menu" style="display: none;">
			<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_4'));">+ 放大字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_4'));">- 缩小字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_4'));">x 恢复默认</a></li>
		</ul>
		<ul class="operation_menu Noprint" id="caption5_menu" style="display: none;">
			<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_5'));">+ 放大字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_5'));">- 缩小字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_5'));">x 恢复默认</a></li>
		</ul>
		<ul class="operation_menu Noprint" id="caption6_menu" style="display: none;">
			<li class="show"><a href="javascript:void(0);" onclick="fontZoom('up', Fid('tab_content_6'));">+ 放大字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('down', Fid('tab_content_6'));">- 缩小字体</a></li>
			<li class="his"><a href="javascript:void(0);" onclick="fontZoom('', Fid('tab_content_6'));">x 恢复默认</a></li>
		</ul>`;
			
	}
}

sub convertdate {
	my ($date) = @_;
	my $result = substr($date, 5, 2);
	$result = $Month_name[$result - 1];
	$result = substr($date, 8, 2) . $result;
	return $result;
}

sub get_template {
	my ($filename) = @_;

	my $fileuploadpath = "d:/upload/trip_template/";
	if (!-e $fileuploadpath) {
		return '';
	}
	elsif(!-d $fileuploadpath) {
		return '';
	}

	$filename = $fileuploadpath . $filename;
	if (!-e $filename) {##文件不存在    liangby@2014-8-5
		return '';
	}
	open(MAIL, "$filename") || die "错误：不能打开文件";
	my $result = '';
	while(my $line = <MAIL>){
		$result .= $line;
	}
	close(MAIL);
	return $result;
}
&Footer();

sub airdate_format{
	local($airdate)=@_;
	if ($airdate eq "") {return "";}
	$airdate=~tr/[a-z]/[A-Z]/;
	my @airdates=split(' ',$airdate);
	return $airdates[0].$airdates[1].substr($airdates[2],2,2);
}
