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

my $imgSize=5 * 1024;	#���ƴ�С5 * 1024 KB   
$CGI::POST_MAX=$imgSize * 1024;#���ƴ�С

## ---------------------------------------------
my $req = new CGI; 
$in{User_ID} = $req->param("User_ID");
$in{Serial_no} = $req->param("Serial_no");
$in{Type} = $req->param("Type");
$in{NewFile} = $req->param("NewFile");

## ---------------------------------------
## ����ļ�ͷ,������HTML
## ---------------------------------------
if ($in{Type} eq "upffp" || $in{Type} eq "") {
	&HTMLHead();
	&Title("");
	if ($in{Type} eq "") {trigger_result(1,"","","�ļ����������ļ���С $imgSize KB��");}
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
	if (! -e $r_ffpdir) {# ���жϴ��ڸ�Ŀ¼
		 mkdir($r_ffpdir,0002);
	}elsif(!-d $r_ffpdir){
		 mkdir($r_ffpdir,0002);
	}
	if (! -e $sub_ffpdir) {# ���жϸ��¼�Ŀ¼
		 mkdir($sub_ffpdir,0002);
	}elsif(!-d $sub_ffpdir){
		 mkdir($sub_ffpdir,0002);
	}
	if (! -e $ffp_dir) {# ����жϱ���Ŀ¼
		 mkdir($ffp_dir,0002);
	}elsif(!-d $ffp_dir){
		 mkdir($ffp_dir,0002);
	}

	if ( $in{Type} eq "upffp") {
		if ($in{NewFile} eq "") {
			trigger_result(1,"","","�ϴ��ļ�����Ϊ��");
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
			trigger_result(1,"","","��Ч���ļ����ͣ�");
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
	
		$fileName=$md5_filename.$extname;  # ��������ļ�������40λ�����
		if (-e "$ffp_dir$fileName") {	   
			my $md5_filenames=substr($md5_filename,2,6);
				$fileName=$txtname.$md5_filenames.$extname;
				$return=201;
		}
		
		open (OUTFILE, ">$ffp_dir$fileName");
		binmode(OUTFILE); #���ȫ�ö����Ʒ�ʽ�������Ϳ��Է����ϴ��������ļ��ˡ������ı��ļ�Ҳ�����ܸ���
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
			$return=qq`"·������"`;
		}elsif ($in{keyword} eq "") {
			$return=($in{keyword1} eq "1")?"Ҫɾ�����ļ��в���Ϊ��":"Ҫɾ�����ļ�����Ϊ��";
		}elsif (!-e $get_url) {
			$return=($in{keyword1} eq "1")?"Ҫɾ�����ļ��в�����":"Ҫɾ�����ļ�������";
		}elsif ($in{keyword1} eq "1"){
			if (!-d $get_url) {
				$return="Ҫɾ�����ļ��в�����";
			}else{
				&deldir($get_url);
				$return="ɾ���ɹ�";
			}
		}else{
			if (-d $get_url) {
				$return="Ҫɾ�����ļ�������";
			}else{
				if (unlink("$get_url")>0) {
					$return="ɾ���ɹ�";
				}else{
					$return="ɾ��ʧ��";
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

