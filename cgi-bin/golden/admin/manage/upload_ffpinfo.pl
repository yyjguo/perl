#!c:/Perl/bin/Perl.exe
require "ctnlib/golden/common.pl";
require "ctnlib/golden/html.pl";
require "ctnlib/golden/cgi-lib.pl";
require "ctnlib/golden/manage.pl";
require "ctnlib/golden/datelib.pl";

use Sybase::CTlib;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use CGI; 
use MD5;
use MIME::Base64;

my $imgSize=5 * 1024;	#限制大小5 * 1024 KB   
$CGI::POST_MAX=$imgSize * 1024;#限制大小

## ---------------------------------------------
my $req = new CGI; 
$in{User_ID} = $req->param("User_ID");
$in{Serial_no} = $req->param("Serial_no");
$in{Type} = $req->param("Type");
$in{NewFile} = $req->param("NewFile");

## ---------------------------------------
## 输出文件头,不缓存HTML
## ---------------------------------------
if ($in{Type} eq "upffp" || $in{Type} eq "") {
	&HTMLHead();
	&Title("");
	if ($in{Type} eq "") {trigger_result(1,"","","文件过大，限制文件大小 $imgSize KB！");}
}else{
	&ReadParse();
	print "Pragma:no-cache\r\n";
	print "Cache-Control:no-cache\r\n";
	print "Expires:0\r\n";
	print "Content-type:text/html;charset=GB2312;\n\n";
}
## ---------------------------------------------
$Corp_ID = &ctn_auth("");
if(length($Corp_ID) == 1) { exit; }
&get_op_type();
## =========================================================
##  jf@2018-01-09
## =========================================================
if ($User_type ne "S" && $User_type ne "O") {
	exit;
}
## ---------------------------------------------
if ($in{Type} ne "") {
	&attach_upload();
}

sub attach_upload{
	my ($ffp_dir,$ffp_url,$r_ffpdir,$sub_ffpdir)=();
	$ffp_dir="D:/www/upload/$Corp_center/ffp_file/";
	$sub_ffpdir="D:/www/upload/$Corp_center/";
	$r_ffpdir="D:/www/upload/";
	$ffp_url="http://$G_SERVER/";
	if (! -e $r_ffpdir) {# 先判断存在根目录
		 mkdir($r_ffpdir,0002);
	}elsif(!-d $r_ffpdir){
		 mkdir($r_ffpdir,0002);
	}
	if (! -e $sub_ffpdir) {# 再判断根下级目录
		 mkdir($sub_ffpdir,0002);
	}elsif(!-d $sub_ffpdir){
		 mkdir($sub_ffpdir,0002);
	}
	if (! -e $ffp_dir) {# 最后判断保存目录
		 mkdir($ffp_dir,0002);
	}elsif(!-d $ffp_dir){
		 mkdir($ffp_dir,0002);
	}

	if ( $in{Type} eq "upffp") {
		if ($in{NewFile} eq "") {
			trigger_result(1,"","","上传文件不能为空");
		}
		my $file=$in{NewFile};
		my $fileName = $file;
		$fileName =~ s/^.*(\\|\/)//;$fileName=~ tr/A-Z/a-z/;$fileName=~ s/\'//g;$fileName=~ s/\"//g;$fileName=~ s/\s*//g;
		my $newmain = $fileName;
		my @newmainprr=split(/\./,$newmain);
		if (scalar(@newmainprr)>1) {
			$extname = ".".lc(pop(@newmainprr));
			$txtname = lc(join(".",@newmainprr));
		}else{
			$txtname = lc(substr($newmain,0,length($newmain) - 4));
			$extname = lc(substr($newmain,length($newmain) - 4,4));
		}
		my $filenotgood;
		my @theext=(".jpg",".gif",".jpeg",".png",".bmp",".7z",".aiff",".asf",".avi",".csv",".doc",".docx",".flv",".gz",".gzip",".mid",".mov",".mp3",".mp4",".mpeg",".mpg",".pdf",".rtf",".ppt",".pptx",".ram",".rar",".rmi",".rmvb",".tar",".tgz",".tif",".tiff",".txt",".vsd",".wav",".wma",".wmv",".xls",".xlsx",".zip");
		
		for(my $i = 0; $i < scalar(@theext); $i++){
			if ($extname eq $theext[$i]){
				$filenotgood = "yes";
				last;
			}
		}
		if ($filenotgood ne "yes" && $txtname ne "") {
			close ($file);
			trigger_result(1,"","","无效的文件类型！");
		}
		$fileName=$txtname."ffp";
		my $return=0;
		$today = &cctime(time);
		($week,$month,$day,$time,$year)=split(" ",$today);
		if($day<10){$day="0".$day;}
		$today = $year.".".$month."."."$day";
		$ttime=$year.$month.$day.$time;
		$ttime=~ s/\:*//g;
		$ttime=~ s/\.*//g;
		use MD5;
		my $context = new MD5;
		$context->reset();
		$context->add($fileName);
		my $md5_filename = $context->hexdigest;
	
		$fileName=$md5_filename.$extname;  # 不会出现文件名大于40位的情况
		if (-e "$ffp_dir$fileName") {	   
			my $md5_filenames=substr($md5_filename,2,6);
				$fileName=$txtname.$md5_filenames.$extname;
				$return=201;
		}
		
		open (OUTFILE, ">$ffp_dir$fileName");
		binmode(OUTFILE); #务必全用二进制方式，这样就可以放心上传二进制文件了。而且文本文件也不会受干扰
		while (my $bytesread = read($file, my $buffer, 1024)) { 
			print OUTFILE $buffer;
		}
		close (OUTFILE);
		close ($file);
		$p_pic = "$ffp_url$fileName";
		trigger_result($return,$p_pic,$fileName,"");
	}
	elsif($in{Type} eq "delfile"){
		$in{keyword1}=($in{keyword1} ne "1")?"0":"1";
		my $return;
		my $get_url=$in{keyword};
		$get_url=~ s/$ffp_url//g;
		$get_url=$ffp_dir.$get_url;
		if (!index($in{keyword},$ffp_url,0)==0) {
			$return=qq`"路径错误"`;
		}elsif ($in{keyword} eq "") {
			$return=($in{keyword1} eq "1")?"要删除的文件夹不能为空":"要删除的文件不能为空";
		}elsif (!-e $get_url) {
			$return=($in{keyword1} eq "1")?"要删除的文件夹不存在":"要删除的文件不存在";
		}elsif ($in{keyword1} eq "1"){
			if (!-d $get_url) {
				$return="要删除的文件夹不存在";
			}else{
				&deldir($get_url);
				$return="删除成功";
			}
		}else{
			if (-d $get_url) {
				$return="要删除的文件不存在";
			}else{
				if (unlink("$get_url")>0) {
					$return="删除成功";
				}else{
					$return="删除失败";
				}
			}
		}
		print qq`$in{callback}({$in{Type}:"$return"})`;
		exit;
	}
}

sub trigger_result{
	local($errorNumber,$fileUrl,$fileName,$customMsg)=@_;
	print qq`
		<script type="text/javascript">
			parent.OnUploadCompleted($errorNumber,"$fileUrl","$fileName","$customMsg");
		</script>`;
		exit;
}

sub deldir {
	my($del_dir)=$_[0];
	if (substr($del_dir,length($del_dir)-1,1) eq "/") {
		$del_dir=substr($del_dir,0,length($del_dir)-1);
	}
	my(@direct);
	my(@files);
	opendir (DIR2,"$del_dir");
	my(@allfile)=readdir(DIR2);
	closedir (DIR2);
	foreach (@allfile){
		if (-d "$del_dir/$_"){
			push(@direct,"$_");
		}
		else {
			push(@files,"$_");
		}
	}
	$files=@files;
	$direct=@direct;
	if ($files ne "0"){
		foreach (@files){
			unlink("$del_dir/$_");
		}
	}
	if ($direct ne "0"){
		foreach (@direct){
			&deldir("$del_dir/$_") if($_ ne "." && $_ ne "..");
		}
	}
	rmdir ("$del_dir");
}
exit;

