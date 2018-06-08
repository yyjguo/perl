require "ctnlib/golden/SMSPost.pl";
require "ctnlib/golden/smstools.pl";
require "ctnlib/golden/air_pay_op.pl";

use Data::Dumper;

##--------------�����б�------------------------
## air_account ��Ʊ����������ѯ
## air_ban  ��Ʊ��ƺ����ѯ
## air_account_recv ��Ʊ������������
## air_account_debt ��Ʊ����Ƿ�����
## inc_account   ������Ʒ����������ѯ
## inc_insure_list ��ȡ�ͻ������ı����б�
## inc_insure_book_resok �����޸ı�������
## inc_account_recv ������Ʒ������������
## inc_account_sp ������Ʒ�����������Ӧ�̲�ѯ
## inc_account_recv_sp ������Ʒ�����������Ӧ�̡���ˡ�ҵ������ˡ�������ˣ�����ǰ������
## air_account_sp   ��Ʊ��Ӧ�����������ѯ
## account_recv_sp ��Ʊ��Ӧ�����������ˡ�ҵ������ˡ�������ˣ�����ǰ������
## air_check  ��Ʊ��˲�ѯ
## refuse_pay_op �հ׵��ܾ�����
## inc_account_debt ������Ʒ����Ƿ�����
##---------------end----------------------------
## =====================================================================
## �������� 
## =====================================================================
sub air_account{
	local($type,$op,$query_only)=@_;
	require "ctnlib/golden/air_op.pl";
	$Start = $in{Start};	
	## ---------------------------------------------------------------------
	## define table header
	##��ȡ�û���Ϣ
	&get_userinfos("","O','S','Y","Y");
	##��ȡ������Ϣ
	$sql=" select IATA_ID,City_cname,City_name from ctninfo..IATA_city ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$city_cname{$row[0]}=$row[1];
			}
		}
	}
	#�Զ����������ֵ�������� fanzy@2015-10-26
	my $sxk_credit=($center_airparm=~/g/ && $in{Corp_ID} ne "" && $in{Corp_ID} ne $Corp_center)?"Y":"N";
	if ($Pay_version eq "1") {
		## ��ƿ�Ŀ����
		@array_list = &get_kemu($Corp_center,"","array",1,"Y");
		
	}else{
		##ԭ�տʽ����Ϣ  
		$sql = "select rtrim(Pay_method),Pay_name,Is_netpay,Is_show,Is_payed,Corp_ID,Pay_pic from ctninfo..d_paymethod 
			where  Corp_ID in ('SKYECH','$Corp_center') 
			order by Order_seq,Is_netpay ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
					$pay_method_hash{$row[0]}[0]=$row[1]; ##����
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
	## �����Ŀ�б�
	my $ass_ids;
	for (my $i = 0; $i < scalar(@array_list); $i++) {
		if ($array_list[$i]{Type_ID} eq $array_list[$i]{Pid}) {		$array_list[$i]{Pid} = '';	}
		my $listitem = qq`['$array_list[$i]{Corp_ID}', '$array_list[$i]{Type_ID}', '$array_list[$i]{Type_name}', '$array_list[$i]{Pid}','0']`;
		push(@tmp_array_list, $listitem);
		if ($array_list[$i]{Pid} ne "") {
			$ass_ids .= "','$array_list[$i]{Pid}";
		}
	}
	## ���������б�
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

	if ($query_only ne "Y") {
		print qq!<form action='air_account.pl' method=post name=book id='book_form' >!;
	}
	$Header = qq!
	<table width="98%" border="0" cellspacing="1" cellpadding="1" bgcolor="dadada">
		<tr align="center" bgcolor="#efefef">!;
	if ($query_only ne "Y" && ($op == 2 ||$op == 0 || $op == 3 || $op == 4)){	
		$Header .= qq!<td width="30" height="30">����</td>!;
	}else{
		$Header .= qq!<td width="30" height="30">&nbsp;</td>!;
	}
	my $h_name;
	if ($in{History} eq "Y"){
		$h_name="��Ʊ����";
	}else{
		$h_name="���ͻ���";
	}
	my $tb_book="_$Top_corp";
	if ($in{History} eq "Y") {	$tb_book="$in{his_year}";	}
	#	<td>����</td>	
	$Header .= qq!<td width=40>$h_name</td>
	<td>��Ա����</td><td>��Ա����</td>
	<td>PNR</td>
	<td>��Ʊ����</td>
	<td>��ƱԱ</td>
	<td width=80>״̬</td>
	<td width=40>֧��</td>
	<td>����</td>
	<td>�����</td>
	<td width="100px">�����г�</td>
	<td>�����</td>
	<td>����</td>
	<td nowrap>Ʊ��</td>
	<td width=40>Ʊ��</td>
	<td width=40>��Ӷ</td>
	<td height=19 width=40>ͬ��</td>
	<td width=30>˰</td>
	<td width=30>����</td>
	<td width=30>����</td>
	<td width=30>�����</td>
	<td width=30>����</td>
	<td width=40>Ӧ��</td>\n!;
	if ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3) {
		$Header .= "<td width=40>ʵ��</td>\n";
	}
	$Header.=qq!<td>������</td><td>��������</td><td>�ڲ�����</td><td>ҵ��Ա</td><td>����Ա</td><td>Ԥ��Ա</td></tr>!;
	## define table tailer
	sub sum_account{
		local($total,$type) = @_;
		
		print qq!<tr align="right" bgcolor="#fffae4">
			<td height="30" colspan="12">&nbsp;</td>
			<td colspan="3" nowrap>�ָ�С�ƣ���Ʊ $CTk_num[$ii] �� ���� $CIn_num[$ii] �ţ���</td>!;
		$CIn_price[$ii] = sprintf("%.2f",$CIn_price[$ii]);
		$COut_price[$ii] = int($COut_price[$ii]);
		$CProfit[$ii] = sprintf("%.2f",$CProfit[$ii]);
		$CService[$ii] = sprintf("%.2f",$CService[$ii]);

		$COrigin_price[$ii] =sprintf("%.2f",$COrigin_price[$ii]);
		$CRecv[$ii] = sprintf("%.2f",$CRecv[$ii]);
		$CTotal[$ii]= sprintf("%.2f",$CTotal[$ii]);

		print qq!<td>$COut_price[$ii]</td><td>$CIn_price[$ii]</td><td>$COrigin_price[$ii]</td>
			<td>$CTax[$ii]</td><td>$CInsure[$ii]</td><td>$CProfit[$ii]</td><td>$CService[$ii]</td>
			<td>$CRecv[$ii]</td><td>$CTotal[$ii]</td>!;
		if ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3) {			
			print qq!<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>!;
		}
		print qq!</tr>
			<tr align="right" bgcolor="#fffae4">
			<td height=30 colspan=12></td>
			<td colspan=3 nowrap>����С�ƣ���Ʊ $TTk_num[$ii] �� ���� $TIn_num[$ii] �ţ���</td>!;
		$TIn_price[$ii] = sprintf("%.2f",$TIn_price[$ii]);
		$TOut_price[$ii] = int($TOut_price[$ii]);
		$TProfit[$ii] = sprintf("%.2f",$TProfit[$ii]);
		$TService[$ii] = sprintf("%.2f",$TService[$ii]);

		$TOrigin_price[$ii] =sprintf("%.2f",$TOrigin_price[$ii]);
		$TRecv[$ii] =sprintf("%.2f",$TRecv[$ii]);
		$TTotal[$ii] =sprintf("%.2f",$TTotal[$ii]);
		print qq!<td>$TOut_price[$ii]</td><td>$TIn_price[$ii]</td><td>$TOrigin_price[$ii]</td>
			<td>$TTax[$ii]</td><td>$TInsure[$ii]</td><td>$TProfit[$ii]</td><td>$TService[$ii]</td>
			<td>$TRecv[$ii]</td><td>$TTotal[$ii]</td>!;
		if ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3) {			
			print qq!<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>!;
		}
		print qq!</tr>!;
		if ($type eq "Y") {
			if ($Find_res > 0) {
				print qq!<tr align="right" bgcolor="#fffae4"><td height=30 colspan=7></td>
				<td colspan=7><b>�ܼƣ���Ʊ $TT_Tk_num �� ���� $TT_In_num �ţ���</td>!;
				$TT_In_price = sprintf("%.2f",$TT_In_price);
				$TT_Out_price = int($TT_Out_price);
				$TT_Profit = sprintf("%.2f",$TT_Profit);
				$TT_Service = sprintf("%.2f",$TT_Service);

				$TT_origin = sprintf("%.2f",$TT_origin);
				$TT_Recv = sprintf("%.2f",$TT_Recv);
				$TT_Total =sprintf("%.2f",$TT_Total);

				print qq!<td>$TT_Out_price</td><td>$TT_In_price</td><td>$TT_origin</td>
					<td>$TT_Tax</td><td>$TT_Insure</td><td>$TT_Profit</td><td>$TT_Service[$ii]</td>
					<td>$TT_Recv</td><td><b>$TT_Total</td>
					<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td>
				</tr>!;
			}
		}
		print qq!</table>!;
	}
	## ---------------------------------------------
	## ���ڼ��
	## ---------------------------------------------
	if(&date_check($Depart_date)==0){
		print qq!<h3 class="tishi">������ʾ�����鿪ʼ���������Ƿ���ȷ��</h3>!;
		exit;
	}
	print qq!<div class="airlines_list scroll_chaoc">!;
	## =================================================================================
	
	$where = "\n from ctninfo..Airbook$tb_book a,
		ctninfo..Airbook_lines$tb_book c,
		ctninfo..Airbook_detail$tb_book g,
		ctninfo..User_info d,
		ctninfo..Corp_info b,
		ctninfo..Corp_info f
	WHERE a.Reservation_ID = c.Reservation_ID 
		and a.Reservation_ID=g.Reservation_ID 
		and c.Reservation_ID=g.Reservation_ID 
		and c.Res_serial=g.Res_serial \n";

	$in{username} =~ s/\s*//g;
	## ��ѯ��Ա����ʱ���ƥ��
	if ($in{username} ne ""){
		$where .=" and d.User_ID = a.User_ID ";
	}else{
		$where .=" and d.User_ID =* a.User_ID ";
	}
	$where .="and d.Corp_num='$Corp_center' 
		and d.User_status='Y' \n";
	if ($in{History} eq "Y" || $in{pay_obj} eq "P" ){##��ʷ�����ó�Ʊ��������     liangby@2008-12-30
	    $where .=" and a.Agent_ID = b.Corp_ID ";
	}else{##���ͻ���
        $where .=" and a.Send_corp = b.Corp_ID ";
	}	
	$where .="	and a.Corp_ID = f.Corp_ID \n";
	$where .= "and a.Sales_ID = '$Corp_center' and b.Corp_num='$Corp_center' and f.Corp_num='$Corp_center' \n";
	if ($in{send_id} ne "") { ##hejc@2017-05-03
		$where .="	and a.Send_corp = '$in{send_id}' \n";
	}
	@parentGroup = split(',', $in{parent_corp});#�����ͻ�
	$size = @parentGroup;
	for($a = 0; $a < scalar(@parentGroup); $a ++ ){
		if($parentGroup[$a] ne ""){
			if ($a<$size-1) {
				$corplesql .= "'$parentGroup[$a]',";
			}else{
				$corplesql .= "'$parentGroup[$a]'";
			}
		}
	}
	if ($corplesql ne '') {
		$where .= " and f.Parent_corp IN ($corplesql)  \n";
	}
	
	##���ﲻӦ��ƥ����ȡ���Ķ���    liangby@2014-2-11
	$where .= " and a.Book_status <> 'C' ";
	$where_the=$where;
	if ($Corp_type ne "T") {
		if ($in{History} eq "Y" || $in{pay_obj} eq "P" ){##��ʷ�����ó�Ʊ��������     liangby@2008-12-30
			if (($Corp_center eq "KWE116" || $Corp_center eq "CTU300") &&  $Is_delivery eq "Y" && ($in{Corp_ID} ne "" ||
				 $in{Res_ID} ne "" || length($in{PNR}) == 5 || length($in{PNR}) == 6 || length($in{tkt_id}) >= 10 ) ) {	
				## ����������Ӫҵ��ָ���ͻ���ѯ��Ӧ�ܲ�ѯ���ͻ����ж���	dabin@2011-11-18
				##�ö����ţ������Ʊ�Ų�Ҳ������   liangby@2011-12-15
			}else{
				$where .= "and a.Agent_ID='$Corp_ID' and b.Corp_ID='$Corp_ID' \n";
			}
		}else{	## ���ͻ���
			if (($Corp_center eq "KWE116" || $Corp_center eq "CTU300") && $Is_delivery eq "Y" && ($in{Corp_ID} ne "" ||
				 $in{Res_ID} ne "" || length($in{PNR}) == 5 || length($in{PNR}) == 6 || length($in{tkt_id}) >= 10 ) ) {	
				## ����������Ӫҵ��ָ���ͻ���ѯ��Ӧ�ܲ�ѯ���ͻ����ж���	dabin@2011-11-18
				##�ö����ţ������Ʊ�Ų�Ҳ������   liangby@2011-12-15
			}
			else{
				$where .= "and a.Send_corp ='$Corp_ID' and b.Corp_ID='$Corp_ID' \n";	
			}
		}				
	}
	if ($in{Res_ID} ne "") {##������
		if (index($in{Res_ID},",")>-1) {##�����Ŵ�
			my @res_temp=split(",",$in{Res_ID});
			my $res_str = join ("','",@res_temp);
			$where .=" and a.Reservation_ID in ('$res_str') and a.Book_status <> 'C' \n";
		}
		else{
			$where .=" and a.Reservation_ID='$in{Res_ID}' and a.Book_status <> 'C' \n";
		}
		##�˵���Ʊ������Ʊ��ͳ�� linjw@2016/11/28
		if($in{Account_period} ne ""){
			if ($in{Corp_ID} ne "") {	$where .= "and a.Corp_ID='$in{Corp_ID}' \n";	}
			my @tkt_id=split(',',$in{tkt_id});my $tkt_len=length($in{tkt_id});
			if (scalar(@tkt_id)==1 && $tkt_len<10) {
				$where .=" and right(rtrim(convert(varchar,g.Ticket_ID)),$tkt_len)='$in{tkt_id}' ";
			}elsif(scalar(@tkt_id)>=1){
				for (my $i=0;$i<scalar(@tkt_id) ;$i++) {
					$tkt_id[$i]=sprintf("%.0f",$tkt_id[$i]);
				}
				my $tkt_id=join(',',@tkt_id);
				$where .=" and g.Ticket_ID in($tkt_id) \n";
			}
		}
	}
	elsif ($in{re_other} ne "Y" && $in{tkt_id} ne "") {##ƥ���λƱ��,������������   liangby@2012-2-8
		my @tkt_id=split(',',$in{tkt_id});my $tkt_len=length($in{tkt_id});
		if (scalar(@tkt_id)==1 && $tkt_len<10) {
			$where .=" and right(rtrim(convert(varchar,g.Ticket_ID)),$tkt_len)='$in{tkt_id}' ";
		}elsif(scalar(@tkt_id)>=1){
			for (my $i=0;$i<scalar(@tkt_id) ;$i++) {
				$tkt_id[$i]=sprintf("%.0f",$tkt_id[$i]);
			}
			my $tkt_id=join(',',@tkt_id);
			$where .=" and g.Ticket_ID in($tkt_id) \n";
		}
		if ($op != 8) {#fanzy@2012-6-12
			$where .=" and a.Ticket_time >= dateadd(month,-1,'$Depart_date')\n";
		}
	}else{
		if ($in{air_type} ne "" && $in{air_type} ne "ALL") {##���ӹ��ں͹�������              liangby@2008-7-22
			$where .=" and a.Air_type ='$in{air_type}' ";
		}
		if (length($in{PNR}) == 5 || length($in{PNR}) == 6) {
			$in{PNR} =~ tr/a-z/A-Z/;
			$where .= " and a.Booking_ref = '$in{PNR}' \n"; 
			if ($type eq "H") {	## ��������
				$where .= "and a.Book_status <> 'C' \n";
					#and a.Book_time >= dateadd(month,-6,getdate()) \n"; #liyongquan@2012/11/8 Booking_ref������
			}
			else{
				$where .= "and a.Book_status = 'H' \n";
			}
		}elsif ($in{re_other} ne "Y" && $in{tkt_id} ne "") {##ƥ���λƱ��,������������   liangby@2012-2-8
			my @tkt_id=split(',',$in{tkt_id});my $tkt_len=length($in{tkt_id});
			if (scalar(@tkt_id)==1 && $tkt_len<10) {
				$where .=" and right(rtrim(convert(varchar,g.Ticket_ID)),$tkt_len)='$in{tkt_id}' ";
			}elsif(scalar(@tkt_id)>=1){
				for (my $i=0;$i<scalar(@tkt_id) ;$i++) {
					$tkt_id[$i]=sprintf("%.0f",$tkt_id[$i]);
				}
				my $tkt_id=join(',',@tkt_id);
				$where .=" and g.Ticket_ID in($tkt_id) \n";
			}
			if ($op != 8) {#fanzy@2012-6-12
				$where .=" and a.Ticket_time >= dateadd(month,-1,'$Depart_date')\n";
			}
		}
		elsif ($in{Account_period} ne "") {	##���˵����ڲ�ѯ
			if (index($in{Account_period},",")>-1) {##�����Ŵ�
				my @period_temp=split(",",$in{Account_period});
				my $period_str = join (",",@period_temp);
				$where .=" and a.Account_period in ($period_str) \n";
			}
			else{
				$where .=" and a.Account_period=$in{Account_period} \n";
			}
			if ($in{Corp_ID} ne "") {	$where .= "and a.Corp_ID='$in{Corp_ID}' \n";	}
		}
		else{
			if ($in{Corp_ID} ne "") {	$where .= "and a.Corp_ID='$in{Corp_ID}' \n";	}
			if ($in{Agent_ID} ne "") {			
				if ($in{History} eq "Y"){##��ʷ�����ó�Ʊ��������     liangby@2008-12-30
					$where .= "and a.Agent_ID='$in{Agent_ID}' \n";
				}else{##���ͻ���
					
					$where .= "and a.Send_corp ='$in{Agent_ID}' \n";	
				}
			}

			if ($in{re_other} eq "Y" && $in{tkt_id} ne "") {##ƥ���λƱ��,������������   liangby@2012-2-8
				my @tkt_id=split(',',$in{tkt_id});my $tkt_len=length($in{tkt_id});
				if (scalar(@tkt_id)==1 && $tkt_len<10) {
					$where .=" and right(rtrim(convert(varchar,g.Ticket_ID)),$tkt_len)='$in{tkt_id}' ";
				}elsif(scalar(@tkt_id)>=1){
					for (my $i=0;$i<scalar(@tkt_id) ;$i++) {
						$tkt_id[$i]=sprintf("%.0f",$tkt_id[$i]);
					}
					my $tkt_id=join(',',@tkt_id);
					$where .=" and g.Ticket_ID in($tkt_id) \n";
				}
				if ($op != 8) {#fanzy@2012-6-12
					$where .=" and a.Ticket_time >= dateadd(month,-1,'$Depart_date')\n";
				}
			}
			if ($in{Send_corp} ne "") {
				$where .=" and a.Send_corp='$in{Send_corp}' ";
			}
			if ($in{Ticket_agent} ne "") {##��Ʊ����  liangby@2010-01-04
			    $where .=" and a.Agent_ID ='$in{Ticket_agent}' ";
			}
			if ($in{Sender} ne "") {	
				if ($in{Sender} eq "%") {	
					$where .= "and a.Sender_ID='' ";	
				}
				else{
					$where .= "and a.Sender_ID='$in{Sender}' ";	
				}
			}
			if ($in{userid} ne "") {	$where .=" and a.User_ID='$in{userid}'\n";	}
			if ($in{username} ne "") {	$where .=" and d.User_name='$in{username}'\n";	}
			if ($in{mobile} ne "") {
				my $mobileph=&JiaMi_ph($in{mobile});
				$where .=" and a.Userbp in ('$in{mobile}','$mobileph')\n";	
			}
			if ($in{user_book} ne "") {	$where .=" and a.Book_ID='$in{user_book}'\n";}
			if ($in{Pay_method} ne "") {	$where .= "and a.Abook_method='$in{Pay_method}'\n";	}
			if ($in{team_name} ne "") {	$in{team_name}=~ tr/a-z/A-Z/; $where .=" and a.Team_name='$in{team_name}'\n";	}
			if ($in{alert_status} ne "") {
				$where .=" and a.Alert_status='$in{alert_status}' ";
			}
			if ($in{book_corp} ne "") {
				$where .=" and a.Book_corp='$in{book_corp}' ";
			}
			if ($in{cyewu} ne "") {
				$where .=" and f.User_ID = '$in{cyewu}' ";
			}
			## �ѳ�Ʊ δ����
			if ($op == 0) {		
				if ($in{Op_detail} eq "1") {##����Ʊδ��,����ͳ�ƹ�����   liangby@2009-12-29
					$where .= "and a.Book_status ='S' ";
				}else{
					$where .= "and ( (a.Book_status in ('P','S','H') and a.Alert_status not in ('1','2') ) or (a.Book_status in ('Y','P','S','H') and a.Alert_status in ('1','2') )) ";
				}
				$where .= "and a.Pay_method='N'
					and (a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out != 0 or a.Agt_total+a.Other_fee+isnull(a.Service_fee,0)+a.Insure_out=0 ) \n ";	
			}elsif ($op == 1) {	## ������ ���Ǻ󷵣��п��ܶ���Ʊ��	dabin@2007-7-24
				$where .= "and a.Book_status in ('Y','P','S','H')
				and a.Pay_method not in ('N','1004.03.02','1004.03.01','1004.04')
				and a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out = 0 \n";	
			}elsif ($op == 2) {	## ������ Ƿ��	
				$where .= "and a.Book_status in  ('Y','P','S','H')
					and a.Pay_method <>'N' \n ";
				## 022000 Ҫ������Ӧ��/Ӧ���ж�	dabin@2011-1-5
				if ($in{account_type} == 1) {	## Ӧ��
					$where .= "and a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out<0\n";
				}elsif ($in{account_type} == 2) {	## Ӧ��
					$where .= "and a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out>0\n";
				}else{
					$where .= "and ((a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out != 0)
					      or (a.AAboook_method='T' and a.Pay_method in ('1004.03.02','1004.03.01','1004.04') and a.Recv_total=0 ) )\n ";
				}
				if ($in{hfcw} eq "Y") {
					$where .=" and (a.AAboook_method<>'T' or (a.AAboook_method ='T' and ((a.Alert_status='0' and  a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out<0)
						or a.Alert_status <>'0' ) )) ";
				}
				##������ͳ�ƹ����Ĳ��� wfc@2013-12-17
				if ($in{qk_type} eq "S") {
					$where .=" and a.Abook_method='S' ";
				}elsif ($in{qk_type} eq "T") {
					$where .=" and a.Abook_method='T' ";
				}elsif ($in{qk_type} eq "O") {
					$where .=" and (a.Abook_method not in ('S','T') and a.Recv_total<=0) ";
				}
			}elsif ($op == 3) {	## �ѳ�Ʊ δ��	
				$where .= "and a.Book_status = 'P' 
					and a.Recv_total =0  and a.Pay_method ='N' \n";	
			}elsif ($op == 4) {	## ������ ��δ��
				$where .= "and a.Book_status='H'
					and a.Alert_status = '0'
					and a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out>0 \n";	
			}elsif ($op == 5) {	## δ�˿�
				$where .= "and a.Book_status in ('P','S') 
					and a.Alert_status in ('1','2') 
					and a.Pay_method='N'
					and a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out != 0 \n";	
			}elsif ($op == 6) {	## ���˿� ��Ʊδ��
				$where .= "and a.Book_status in ('P','S','H')
					and a.Alert_status in ('1','2') 
					and a.Is_voucher <> 'S'
					and a.Left_total=0 \n";	
			}elsif ($op == 7) {	## ���˿� ��Ʊ����
				$where .= "and a.Book_status in ('P','S','H')
					and a.Alert_status in ('1','2') 
					and a.Is_voucher='S'
					and a.Left_total=0 \n";	
			}elsif($op ==8 ){##��Ʊ�� ��Ʊ�������˷�δ�˿��˿�   liangby@2014-8-27
				$where .= "and a.Book_status in ('P','S','H') 
					and a.Alert_status in ('1','2') 
					and a.Tag_str like '%P%'
					and a.Recv_total-a.Agt_total-a.Other_fee-isnull(a.Service_fee,0)-a.Insure_out != 0 \n";	
			}elsif ($op == 9) {	## ����ȷ�ϵ� fanzy@2012-6-8
			}else{
				print "<div align=left><br><font color=red>��ʾ���Բ�����ʱ��֧�ָò�����</div></td></tr></table>";
				exit;
			}
			if ($op != 9) {#fanzy@2012-6-12
				if ($in{date_type} eq "B") {
					$where .= "and a.Send_date >= '$Depart_date'
						and a.Send_date < '$End_date'\n";
				}
				elsif ($in{date_type} eq "S") {
					$where .= "and a.S_date >= '$Depart_date'
						and a.S_date < '$End_date'\n";
				}
				elsif ($in{date_type} eq "A") {
					$where .= "and c.Air_date >= '$Depart_date'
						and c.Air_date < '$End_date'\n";
				}elsif ($in{date_type} eq "C") {##�˷ϵ��������   liangby@2015-9-25
					$where .= "and a.Reservation_ID in (select distinct Reservation_ID from ctninfo..Res_op k where 
					    k.Reservation_ID=a.Reservation_ID and k.Res_type='A' and k.Operate_type='g' and k.Operate_time>='$Depart_date' 
							and k.Operate_time<'$End_date' )  and a.Alert_status in ('1','2')  \n";
				}
				else{
					$where .= "and a.Ticket_time >= '$Depart_date'
						and a.Ticket_time < '$End_date'\n";
				}
			}
			if ($in{ET_type} ne "") {## Ʊ֤����  liangby@2011-5-27	
					$where .=" and g.Is_ET ='$in{ET_type}' ";
			}
			if ($in{user_book} ne "") {	$where .=" and a.Book_ID='$in{user_book}'\n";}
			if ($in{Guest_name} ne "") { ##�Ƶ�������       liangby@2009-4-9
				##�ĳ�ģ����ѯ,��������Ҫ��    liangby@2012-2-8
				$where .= " and g.First_name like '%$in{Guest_name}%' \n";	
			}
			if ($in{PY_name} ne "") {	 ##�������ƴ������(ģ����ѯ)		linjw@2016-05-31
				$in{PY_name} =~ tr/a-z/A-Z/;				
				$where .= " and g.PY_name like '%$in{PY_name}%' \n";
			}			
		}
	}
	if ($op == 9) {	## ����ȷ�ϵ� fanzy@2012-6-8
		$where.=" and a.Book_status in ('P','S','H')
			and a.Alert_status = '0'
			and a.Reservation_ID in (
			select y.Cust_name
			from ctninfo..Inc_book z,
			   ctninfo..Inc_book_detail y
			where  z.Res_ID=y.Res_ID
				and y.Sales_ID='$Corp_center'
				and z.Corp_ID='$Corp_ID'
				and z.Pro_id=11
				and z.Book_status in ('P','S','H')
				and z.Book_time>='$Depart_date'
				and z.Book_time < '$End_date')\n";
	}
	if ($in{Level_ID} ne "") {
		$where .= " and f.Corp_level='$in{Level_ID}' \n";
	}
	## ---------------------------------------------------------------------
	&show_air_js();
	print qq?\n<script>	
	function OpenWindow(theURL,winName,features) { 
	  window.open(theURL,winName,features);
	}
	function Show_comm(resid){
		OpenWindow('air_comm_do.pl\?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&Refresh=N','C_'+resid,'scrollbars,width=540,height=400,left=200,top=200');
	}
	function Show_relate(resid,pnr){
		OpenWindow('air_relate.pl\?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&PNR='+pnr+'&Reservation_ID='+resid,'R_'+resid,'scrollbars,width=360,height=280');
	}
	</script>?;
	## ----------------------------------------------------------------------------
	## ��ѯ�µĸ��ʽ����	dabin@2010-12-11
	my %pay=&get_dict($Corp_center,4,"","hash");
	## ��ѯ�跽��Ŀ��Ϣ->���ʽ
	my %pay_method=&Get_pay_method("N","hash");
	%kemu_hash = &get_kemu($Corp_center,"","hash","","");
	%pay_method=(%pay_method,%kemu_hash);
	my $i=$w = 0;
	$sql="select rtrim(a.Reservation_ID),right(convert(char(10),c.Air_date,102),5),c.Departure,c.Arrival,
		a.User_ID,g.Res_serial,rtrim(c.Airline_ID+c.Flight_no),g.First_name,
		g.Seat_type,g.Origin_price,g.In_price,g.Out_price,
		g.Insure_type,g.Insure_inprice,g.Insure_outprice,a.Pay_method,
		a.Corp_ID,f.Corp_csname,b.Corp_csname,a.Book_status,
		a.APay_method,rtrim(a.Card_no),f.Corp_num,a.Abook_method,
		g.Insure_num,a.Agt_total+a.Insure_out,a.Recv_total,
		a.Agt_total+a.Insure_out+a.Other_fee+isnull(a.Service_fee,0)-a.Recv_total,rtrim(a.Booking_ref),g.Tax_fee+g.YQ_fee,
		g.Recv_price,g.Ticket_ID,g.In_discount,g.Agt_discount,0,g.Is_ET,
		g.Air_code,g.Other_fee,a.Sender_ID,g.Dept_ID,a.Is_reward,a.Is_team,a.Adult_num,
		a.Is_lock,g.Last_name,convert(char(10),a.Ticket_time,102),convert(char(10),c.Air_date,102),a.AAboook_method,a.Relate_ID,
		a.Alert_status,a.Agt_total+a.Insure_out+a.Other_fee+isnull(a.Service_fee,0),a.Net_book,a.Left_total,datediff(day,a.Ticket_time,getdate()),
		a.Tag_str,a.If_out,a.Is_voucher,a.Pay_status,isnull(g.Service_fee,0),a.Pay_date,a.Pay_user,rtrim(a.Old_resid),g.Air_discount,a.Air_type,
		a.Book_type,g.Passage_type,a.ContractNo,f.User_ID,d.User_name,a.Book_ID ";  ##row[69]
	my @temp_book=();#	fanzy@2012-11-1
	if ($in{Select_the} ne "") {
		my $Select_the=$in{Select_the};$Select_the=~ s/,/','/g;
		$sql_the=$sql.$where_the;
		$sql_the.=" and a.Reservation_ID in ('$Select_the') ";
		$sql_the.=" order by a.Corp_ID,a.Book_time,g.Res_serial,g.Ticket_ID ";
		$db->ct_execute($sql_the);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					push(@temp_book,[@row]);
					push(@resid,$row[0]);
					if($row[49] eq "1" && $row[61]=~/\d{10,}/){  ##ԭ������
						push(@oldresid,$row[61]);
#						$res_map{$row[61]}=$row[0];
					}
				}
			}
		}
		$where.=" and a.Reservation_ID not in ('$Select_the') ";
	}
	$sql .= $where;
	$sql .= " order by a.Corp_ID,a.Book_time,g.Res_serial,g.Ticket_ID "; 
	#if ($in{User_ID} eq "admin") {
		#print "<pre>$sql</pre>";
		#exit;
	#}
	## ---------------------------------------------------------------------
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				push(@temp_book,[@row]);
				push(@resid,$row[0]);
				if($row[49] eq "1" && $row[61]=~/\d{10,}/){  ##ԭ������
					push(@oldresid,$row[61]);
#					$res_map{$row[61]}=$row[0];
				}
			}
		}
	}
	if($Corp_center eq "PEK615" && scalar(@oldresid)>0 && $query_only ne "Y" && $op == 5 && $in{History} ne "Y"){ ##��Դȫ����Ʊ����ԭ��������Ϻ�������� lyq@2015-11-13
		%count=();
		@oldresid = grep { ++$count{$_} < 2 } @oldresid;
		$oldresids=join("','",@oldresid);
		my $sql=qq`select rtrim(Reservation_ID) from ctninfo..Airbook$tb_book where Reservation_ID in ('$oldresids') and Recv_total-Agt_total-Insure_out-Other_fee-isnull(Service_fee,0)<0 at isolation 0`;
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$old_resid_hs{$row[0]}='N';
				}
			}
		}
	}

	my @resid_old=sort keys(%res_map);
#	if(scalar(@resid_old) > 0){	##��Ʊ��ĸ�����һ��������¼�����һ��֧����ʽ	linjw@2018-02-26
#		$oldresid_str=join("','",@resid_old);
#		my $sql="select rtrim(Reservation_ID),Pay_serial,Pay_object,Pay_bank from ctninfo..Airbook_pay$tb_book where Reservation_ID in ('$oldresid_str') 
#				group by Reservation_ID having Pay_serial=max(Pay_serial) order by Operate_time  \n";
#		#print "<pre>$sql";
#		$db->ct_execute($sql);
#		while($db->ct_results($restype) == CS_SUCCEED) {
#			if ($restype==CS_ROW_RESULT)	{
#				while(@row = $db->ct_fetch)	{
#					$refund_pay{$res_map{$row[0]}}{Pay_object}=$row[2];
#					$refund_pay{$res_map{$row[0]}}{Pay_bank}=$row[3];
#					#print "$row[0]---------$row[2] --------- $row[3]----$res_map{$row[0]}";
#				}
#			}
#		}
#		$refund_pay_info=Dumper(\%refund_pay);
#		$refund_pay_info=~ s/ \=\> /\:/g;
#		$refund_pay_info=~ s/\:undef/\:\'\'/g;
#		$refund_pay_info=~ s/\n//g;
#		$refund_pay_info=~ s/ //g;
#		$refund_pay_info=~ s/\$VAR1/var refund_pay/;
#	}
	
	## �����ظ��Ķ����ţ����������з�ҳ����	dabin@2012-12-27
	
	%count=();

	@resid=grep { ++$count{ $_ } < 2; } @resid;
	$Total_num=scalar(@resid);
	
	my $records = 10;
	$Start = $in{Start};	if($in{Start} eq "" || $in{Start} eq " ") { $Start=1; }
	## ����Ա��ͻ���ѯʱ����ʾȫ������
	#if ($in{userid} ne "" || $in{Corp_ID} ne "" || $in{Sender} ne "") {	$records=$Total_num;	}
	if ($Total_num>$records) {##����10�ŷſ�,����С��10�Ķ��˶�������ʾ��ȫ    liangby@2016-11-24
		$records=$Total_num;	## �ſ���ҳ	dabin@2012-12-28
	}
	
	my %ccptd=();my @HCityRs=();
	my $temp_id = $tid = $corpid = $tmp_serial = "";
	my $Air_date = "";
	$ii = -1;
	my $Find_res = 0;
	my $order_serial=0;
	@price=(0,0,0,0);
	for (my $k=0;$k<scalar(@temp_book) ;$k++) {
		my @row=@{$temp_book[$k]};
		if ($tid ne $row[0]){	## �¶���
			$tid = $row[0];		$Find_res ++;
			$order_serial=0;
		}
		
		#if($Find_res<=$Start*$records && $Find_res>($Start-1)*$records ){
			
			my $Pay_method=$pay{$row[23]};		my $card_no="<span title='$row[68] ��Ӷ����'>$row[4]</span>";	## ��Ա��
			my $s_city = $row[2];		my $e_city = $row[3];		my $tk_id=$row[31];		my $in_dis=$row[32];
			my $agt_dis=$row[33];		my $r_price=$row[30];		my $insure=0;
			my $a_code=$row[36];		my $is_et = "-";			my $contract_no=$row[66];
			if ($tk_id eq "0") {	$tk_id="0000000000";	}
			if ($a_code eq "") {	$a_code="000";			}					
			## �ͻ����ʽ	 Abook_method
			my $j_pay=$row[23];			my $in_num=$row[24];		my $t_in=int($row[25]);		
			my $t_recv=sprintf("%.2f",$row[26]);	my $t_left=sprintf("%.2f",$row[27]);		
			my $p_status = $row[39];	
			if ($p_status eq "1") {	$p_status = "<font color=red title='��Ʊ'><strike>";	}
			elsif ($p_status eq "2") {	$p_status = "<font color=magenta title='����'><u>";	}
			else{	$p_status = "";	}
			#my $is_reward=$row[40];		
			#if ($is_reward eq "N") {	$is_reward="<font color=red>-";	}	else	{	$is_reward="";	}
			my $is_team=$row[41];		my $person_num=$row[42];
			my $is_lock = $row[43];		if($is_lock eq "Y") {$is_lock = 1;} else {$is_lock = 0;}
			if ($is_lock == 1) {
				$card_no .= "<img src='/admin/index/images/lock.gif' align=absmiddle alt='�ѹ���'>";
			}
			my $res_tmp=$row[5];			my $last_tmp=$row[44];
			my $ticket_tmp = $row[45];		my $airdate_tmp=$row[46];
			my $abook_method = $row[47];	my $relate_id=$row[48];	
			my $is_refund=$row[49];         my $Net_book=$row[51];    
			my $bk_status = "����";			
			
			if ($row[19] ne "C" && ($is_refund eq "1" || $is_refund eq "2")) {
				$bk_status="".&get_refund_status($row[19],$row[54],$row[56],$row[57],$t_left,"<br>");
			}else{
				$bk_status = &cv_airstatus($row[19],"S",$t_left,$row[20],$is_refund,$row[54],$row[55],$abook_method);
			}
			my $left_total=$row[52];  ##δ�ս�� chengzx@2013-8-19
			my $current_day_ticket=$row[53]; ##��Ʊ���� dingwz@2014-06-19
			my $tag_str=$row[54];
			my $send_tagstr="";
			if ($relate_id ne "") {
				$send_tagstr.=qq!<a href="javascript:Show_relate('$row[0]','$pnr')" title='��������'><img src='/admin/index/images/list.gif' align=absmiddle border=0></a>!;
			}
			if ($tag_str=~/��/){
				$send_tagstr.=qq!<span><b>��</b></span>!;
			}
			if ($tag_str=~/��/){
				if ($Corp_center eq "PEK615") {
					$send_tagstr.=qq!<span title="��-����"><b>��</b></span>!;
				}else{
					$send_tagstr.=qq!<span><b>��</b></span>!;
				}
			}
			if ($tag_str=~/��/){
				if ($Corp_center eq "PEK615") {
					$send_tagstr.=qq!<span title="��-Ԥ�㵥λ"><b>��</b></span>!;
				}else{
					$send_tagstr.=qq!<span><b>��</b></span>!;
				}
			}
			if ($tag_str=~/��/){
				$send_tagstr.=qq!<span style="color:red;"><b>��</b></span>!;
			}
			if ($tag_str=~/��/){
				$send_tagstr.=qq!<span style="color:red;"><b>��</b></span>!;
			}
			if ($tag_str=~/��/){
				$send_tagstr.=qq!<span style="color:red;"><b>��</b></span>!;
			}
			#if ($tag_str=~/��/){
			#	$send_tagstr.=qq!<img src="/admin/index/images/term_rt.gif" title="eTermֱ������" border="0" />!;
			#}
			$res_corpids{$row[16]}=$corpid;
			## -------------------------------------------------------------------
		
			if ($corpid ne $row[16]){
				if($corpid ne "" ){	## ��ʾ�ɿͻ����ܼ�����
				
					&sum_account();
				}
				print qq!<table width="98%" border="0" cellspacing="1" cellpadding="1" bgcolor="dadada">
				<tr bgcolor="#ffffff"><td height="20"><span class="float font14">&nbsp;&nbsp;<b>�ͻ����ƣ�$row[17]��$row[16]��</b></span></td></tr></table>!;
				print $Header;
				$ii++;
				$COrigin_price[$ii]=0;		$CIn_price[$ii]=0;			$COut_price[$ii]=0;
				$CTax[$ii]=0;				$CTotal[$ii]=0;				#$CProfit[$ii]=0;
				$CInsure[$ii]=0;			$CRecv[$ii]=0;				$CService[$ii]=0;
				$CIn_num[$ii]=0;			$CTk_num[$ii]=0;
				$TOrigin_price[$ii]=0;		$TIn_price[$ii]=0;			$TOut_price[$ii]=0;
				$TTax[$ii]=0;				$TTotal[$ii]=0;				#$TProfit[$ii]=0;
				$TInsure[$ii]=0;			$TRecv[$ii]=0;				$TService[$ii]=0;
				$TIn_num[$ii]=0;			$TTk_num[$ii]=0;
				$corpid = $row[16];			 
			}
			
			my $other_fee=$row[37];
			my $service_fee=$row[58];
			if ($temp_id ne $row[0]){	## �¶���
			    $can_modify_insure="N";
				my $c_pay=$pay_method{$row[15]};	
				if ($c_pay eq "") {	$c_pay="&nbsp;";	}
				my $sender=$row[38];
				$sender=$USER_NAME{$sender}[1] ne ""?"<span title='$sender'>$USER_NAME{$sender}[1]</span>":$sender;
				if ($sender eq "" || $sender eq " ") {	$sender="&nbsp;";	}
				$tmp_serial = $row[5];
				my $pnr=$row[28];	
				if ($pnr eq "") {	$pnr="-----";	}
				else{
					$pnr = qq!<a href="javascript:Show_pnr('$row[0]','$pnr');" title='��ȡ����'>$pnr</a>!;						
				}
				print qq!<tr class="odd" onmouseout="this.style.background='#ffffff'" onmouseover="this.style.background='#fef6d5'">!;
				if ($Find_res == 1) {##chengzx@2013-8-19
                       if (($type eq "H" && $row[19] ne "H" && $left_total>0) || $type eq "A") {
						  $jump_w = qq!Show_pay('$row[0]','');!;
						}
				}
				$Air_date=$row[1];	
				if ($temp_id ne "") {
					$out_total = $total_tmp;
					$total_tmp = 0;
					$comm_t = $comm_tmp;
					$comm_tmp = 0;
					push(@o_price,$out_total);	push(@i_price,$out_total);	push(@c_comm,$comm_t);	

				}
				
				push(@i_select,0);
				push(@lock,$is_lock); 
				if ($query_only ne "Y" && ($op == 2 ||$op == 0 || $op == 3 || $op == 4 || $op == 5) && $in{History} ne "Y"){##����ͨ���ͻ���ѯʱ����������������      liangby@2008-6-17
					my $l_dis;
					if (($is_lock eq "1" || $t_left ==0 ) && $row[50] !=0 ) {##�ѹ���Ĳ�������������            liangby@2008-6-3
					 
					   $l_dis="disabled title='�ѹ���Ĳ�������������' ";
					}
					
					if ($row[15] ne "N" && $row[15] ne "1004.03.02" &&  $row[15] ne "1004.03.01" && $row[15] ne "1004.04" && $row[50]==0) {##�������Ϊ0�Ĳ���һ��������   liangby@2013-11-29
						$l_dis="disabled title='�������Ϊ0�Ĳ���һ��������' ";
					}
					if ($row[19] ne "P" && $row[19] ne "S" && $row[19] ne "H") {## ���ǵ���ǰ������δ��Ʊ����������������	 dabin@2011-1-14
						$l_dis="disabled title='δ��Ʊ����������������' ";
					}
					if ($Net_book eq "3") {##Զ��ӿڶ���������������   liangby@2011-7-29
						$l_dis="disabled title='������ԴΪ3������������' ";
					}
					if($old_resid_hs{$row[61]} eq "N"){ ##��ԴȫԴ��δ����Ĳ�������
						$l_dis="disabled title='δ����Ĳ�������' ";
					}
					if ($is_lock ne "1" && $l_dis eq "") { ## ѡ��ȫ��js
					   $ck_all .= "document.book.cb_$i.checked = document.book.cb.checked;\n";
					}
					if($l_dis eq ""){
					    $can_modify_insure="Y";
					}
					print qq!<td align=center width=30>
						<input type=checkbox  name=cb_$i id=cb_$i value='$row[0]' $l_dis onclick="if (document.book.cb_$i.checked) { i_select[$i]=1; if(document.book.sh_event.value==1){ call_recv($i);} else { if (book.all_type[0].checked){ cal_recv();} } } else {  i_select[$i]=0; if (book.all_type[0].checked){ cal_recv();} };upt_Select_the();" class="radio_publish">
						</td>!;
				}
				else{	print "<td></td>";	}                
				if ($query_only eq "Y" ) {
					print qq!<td>$row[18]$send_tagstr</td>
						<td>$card_no$is_reward</td><td>$row[68]</td>!;
				}
				else{
					print qq!<td><a href="javascript:Show_pay('$row[0]','')" title='��������'>$row[18]</a>$send_tagstr</td>
						<td><a href="javascript:Show_comm('$row[0]')">$card_no$is_reward</a></td><td>$row[68]</td>!;
				}
				#<td align=center>$Pay_method</td>	
				my $tkt_tmp=substr($ticket_tmp,2,8);
				print qq!\n<td align=center>$pnr</a></td>
				<td>$tkt_tmp</td>
				<td>$sender</td>
				<td align=center><a href="javascript:Show_his('$row[0]');" title='������¼'>$bk_status</td>
				<td height=20 align=center>$c_pay</td>
				<td align=center><a href="javascript:Show_book('$row[0]');" title='�鿴����'>$Air_date</td>
				<td align=center>$s_city$e_city&nbsp;</td>					
				<td align=center width="100px">$city_cname{$s_city}-$city_cname{$e_city}</td>					
				<td align=center>$row[6]</td>!;
				$temp_id = $row[0];$Res_serial=0;push(@HCityRs,$row[3]);
				$i++;
			}
			else{
				print qq!<tr bgcolor="#ffffff">!;
				if( $tmp_serial eq $row[5]){	## �Ϻ���
					if ($op == 1 || $op == 2 ||$op == 0 || $op == 3 || $op == 4 || $op == 5 || $op == 7){
						print "<td height=20 colspan=13>��</td>";
					}
				}
				else{	## �º���
					$tmp_serial = $row[5];$Res_serial++;push(@HCityRs,$row[3]);
					$Air_date=$row[1];
					if ($op == 1 || $op == 2 ||$op == 0 || $op == 3 || $op == 4 || $op == 5 || $op == 7){
						print "<td height=20 colspan=9>��</td>";
					}
					print  "<td align=center>$Air_date</td>
						<td align=center>$s_city$e_city&nbsp;</td>
						<td align=center width='100px' >$city_cname{$s_city}-$city_cname{$e_city}</td>
						<td align=center>$row[6]</td>";						
				}
			}
			## ����
			$row[7] = &cut_str($row[7],8);
			if($row[12] eq "F" && $row[14] == 0){
				print "<td>$p_status$row[7]<font color=red>-$in_num</td>";
			}				
			else{
				if ($in_num > 0) {
					print "<td>$p_status$row[7]<font color=blue>+$in_num</td>";	
					#$recv = $recv + $in_num * $row[14];
					$insure = $row[14] * $in_num ;
					
				}else{
					print "<td>$p_status$row[7]</td>";
				}
			}
			## ���ʽ	
			my $a_price=$row[9];	my $i_price=$row[10];		my $o_price=$row[11];
			my $tax=$row[29];	
			my $recv=$a_price+$tax-$r_price+$other_fee+$service_fee+$insure;
			my $agt_amount=$a_price+$tax+$other_fee+$service_fee+$insure;
			$r_price =~ s/\s*\.00//;		$a_price =~ s/\s*\.00//;	
			$i_price =~ s/\s*\.00//;		$o_price =~ s/\s*\.00//;	
			## ��Ӷ
			my $comm = sprintf("%.2f",$o_price-$a_price);
#			if($abook_method eq "T" && $op == 0  ){##��
#				$recv=$o_price+$tax-$r_price+$other_fee+$service_fee;
#			}
#			elsif($abook_method eq "T" && $op == 2){##��ȫǷ��,�п��ܲ�������  liangby@2011-1-6  
#				## && ($r_price==0 || (abs($r_price) < abs($a_price+$tax+$other_fee+$service_fee))) ע�͵�������������ᵼ��Ƿ��Ӧ���ܼƺ���ϸ���ܼƶԲ���	dabin@2012-08-07
#				##($in{account_type}==1 || $in{account_type} ==2) ||    liangby@2014-1-1
#				if ( ($r_price==0 || (abs($r_price) < abs($a_price+$tax+$other_fee+$service_fee)))) {##����ͳ�Ƶ�Ƿ��Ӧ��Ӧ��������㷨,���������Ļ�����ԭ�����㷨   liangby@2012-8-9
#					$recv=$o_price+$tax-$r_price+$other_fee+$service_fee;
#				}
#			}
			if ($abook_method eq "T" ) {
				##�㷨�ĳɺ͵���������һ��    liangby@2015-8-4
				if ($recv > 0 && $agt_amount>0 && ( $is_refund eq "0" || $is_refund eq "4" || $is_refund eq "5" )) {##������
					$recv=$o_price+$tax-$r_price+$other_fee+$service_fee+$insure;	
				}
                if (($is_refund eq "1" || $is_refund eq "2") && $recv <0) {##�˷ϵ�
					$recv=$o_price+$tax-$r_price+$other_fee+$service_fee+$insure;
                }
				if ( abs($r_price)== abs($a_price+$tax+$other_fee+$service_fee+$insure)) {##
					if (($Pay_method eq "1004.03.02"||  $Pay_method ne "1004.03.01" || $Pay_method eq "1004.04") && ($a_price+$tax+$other_fee+$service_fee)==0) {
						##Ӧ��Ϊ0��Э����˵�
					}else{
						$recv=$a_price+$tax-$r_price+$other_fee+$service_fee+$insure;
					}
				}
			}
			
			##Ϊ�˱�֤�������ݵ�׼ȷ�ԣ�ʹ����λС��
			if($abook_method eq "T" && $op == 2 && $is_refund =~ /[12]/){	## ���˷�Ʊ����δȫ������ʱ��Ƿ��Ӧ�����㣬Ӧ�۳�Ӷ��	dabin@2014-01-01
				if ($in{account_type} ==2 && $recv != -1*$comm) {	
					$recv=$recv-$comm;
				}
			}
			$recv = sprintf("%.2f",$recv);
			if($row[23] eq "C"){ 	## �ָ����						
				$COrigin_price[$ii] = $COrigin_price[$ii] + $a_price;
				$CIn_price[$ii] = $CIn_price[$ii] + $comm;
				$COut_price[$ii] = $COut_price[$ii] +$o_price ;
				$CTax[$ii] = $CTax[$ii] + $tax + $yq;
				$CTotal[$ii] = $CTotal[$ii] + $recv;
				$CProfit[$ii] = $CProfit[$ii] + $other_fee;
				$CService[$ii] = $CService[$ii] + $service_fee;	
				$CInsure[$ii] = $CInsure[$ii] + $insure;	
				$CRecv[$ii] = $CRecv[$ii] + $r_price;	
				$CIn_num[$ii] = $CIn_num[$ii] + $in_num;	
				$CTk_num[$ii]++;
			}
			else {	## ���˽��
				$TOrigin_price[$ii] = $TOrigin_price[$ii] + $a_price;
				$TIn_price[$ii] = $TIn_price[$ii] + $comm;
				$TOut_price[$ii] = $TOut_price[$ii] + $o_price;
				$TTax[$ii] = $TTax[$ii] + $tax+ $yq;
				
				$TTotal[$ii] = $TTotal[$ii] + $recv;
				$TProfit[$ii] = $TProfit[$ii] + $other_fee;
				$TService[$ii] = $TService[$ii] + $service_fee;
				$TInsure[$ii] = $TInsure[$ii] + $insure;	
				$TRecv[$ii] = $TRecv[$ii] + $r_price;	
				$TIn_num[$ii] = $TIn_num[$ii] + $in_num;	
				$TTk_num[$ii]++;
			}				
			$TT_origin = $TT_origin  + $a_price;
			$TT_In_price = $TT_In_price + $comm;
			$TT_Out_price = $TT_Out_price + $o_price;
			$TT_Tax = $TT_Tax + $tax + $yq;
			$TT_Total = $TT_Total + $recv;
			$TT_Profit = $TT_Profit + $other_fee;
			$TT_Service = $TT_Service + $service_fee;
			$TT_Insure = $TT_Insure + $insure;	
			$TT_Recv = $TT_Recv + $r_price;	
			$TT_In_num = $TT_In_num + $in_num;	
			$TT_Tk_num++;
			$rec_sing=$recv;
			$total += $recv;
			$total_tmp += $recv;
			$comm_t += $comm;
			$comm_tmp += $comm;
			if($abook_method eq "T") {	
				$comm = "$comm";
			}
			if ($recv > 0) {	$recv = "<font color=red>$recv";	}
			my $Insure_list="";
			if ($can_modify_insure eq "Y" && $current_day_ticket ==0 && ($Corp_center eq "CZZ259" || $Corp_center eq "ESL003")){
			    my $idx=$Find_res-1;
		        ## �޸ı������� dingwz@2014-06-18
			    $Insure_list.=" + <select name='inc_insure_num_$row[0]_$order_serial' onchange='total_insure(this);'><option value='0'>0</option><option value='1'>1</option><option value='2'>2</option><option value='3'>3</option><option value='4'>4</option><option value='5'>5</option></select> <input type='hidden' name='inc_insure_remark_$row[0]_$order_serial' value='$row[2]��$row[3]'/><input type='hidden' name='inc_insure_num_hidden' value='0' idx='$idx' id='insure_inc_insure_num_$row[0]_$order_serial'/>";
	        }
			## Ʊ��
			#if ($is_team eq "Y") {	$is_team = "<font color=blue>$person_num*</font>";	}	else{	$is_team="";	}
	#				<td align=center>$agt_dis</td>	
			print "<td nowrap>$a_code-$tk_id</td>
			<td align=right>$o_price</td>
			<td align=right><font color=red>$comm</td>
			<td align=right>$a_price</td>
			<td align=right>$tax</td>
			<td align=right>$insure  $Insure_list</td>
			<td align=right>$other_fee</td>
			<td align=right>$service_fee</td>
			<td align=right>$r_price</td>
			<td align=right>$recv
				<input type=hidden name=resia_$w value='$row[0]'>
				<input type=hidden name=airdate_tmp_$w value='$airdate_tmp'>
				<input type=hidden name=tcomm_tmp_$w value='$comm'>
				<input type=hidden name=ticket_tmp_$w value='$ticket_tmp'>
				<input type=hidden name=res_tmp_$w value='$res_tmp'>
				<input type=hidden name=last_tmp_$w value='$last_tmp'>
				<input type=hidden name=new_recv_price_$w value='$row[30]' />
				<input type=hidden name=alert_status_$w value='$is_refund' /> \n";
			if ($in{Op} ne 0 && $in{Op} ne 2 && $in{Op} ne 3) {
				print "<input type=hidden name=recv_account_$w value='$rec_sing'>";
			}
			print "</td>";
			if ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3) {
				my $iii=$i-1;
				print qq`<td align=right><input type=text name='recv_account_$w' id='recv_account_$iii\_$res_tmp\_$last_tmp' value='$rec_sing' class="input_txt" style='color:blue;width:45px;' onblur="if (document.book.cb_$iii.checked) { i_select[$iii]=1; if(document.book.sh_event.value==1){ call_recv($iii);} else { if (book.all_type[0].checked){ cal_recv();} } } else {  i_select[$iii]=0; if (book.all_type[0].checked){ cal_recv();} }"></td>`;
			}
			my ($yewu_name,$checker,$bookers)=();
			if ($row[16] eq $Corp_center ) {
				$yewu_name="&nbsp;";
			}else{
				$yewu_name=$row[67]." ".$USER_NAME{$row[67]}[1];
			}
			$checker=$row[60]." ".$USER_NAME{$row[60]}[1];
			$bookers=$row[69]." ".$USER_NAME{$row[69]}[1];
			#if ($profit < 0) {	print "<td align=right><font color=red>$profit</td>";	} else {	print "<td align=right>$profit</td>";	}
			print qq`<td>$row[0]</td><td align=center title="����Ա��$row[60]\n�������ڣ�$row[59]">$row[59]&nbsp;</td>
					 <td nowrap>$contract_no</td><td>$yewu_name</td><td>$checker</td><td>$bookers</td></tr>\n`;
			if ($Res_serial==0 && scalar(@resid)==1 && $row[49] eq "0") {
				print qq!<tr id="ccptdto_$last_tmp" style='display:none' bgcolor="#ffffff">!;
				if ($op == 1 || $op == 2 ||$op == 0 || $op == 3 || $op == 4 || $op == 5 || $op == 7){
					print "<td height=20 colspan=12>��</td>";
				}else{
					print "<td height=20 colspan=11>��</td>";
				}
				print qq`<td colspan=12><span id="ccptd_$last_tmp" data="$row[44],$row[65]"><!--����ȯ--></span></td></tr>`;
				$ccptd{resid}=$row[0];$ccptd{userid}=$row[4];$ccptd{agttotal}=$row[50];
				$ccptd{discount}=$row[62];$ccptd{Air_type}=$row[63];$ccptd{Book_type}=$row[64];$ccptd{Net_book}=$row[51];
				$ccptd{num}=$last_tmp;
			}
			$w ++;
			$order_serial++;
#		}
	}
	$total_tmp += $recv;
	$comm_tmp += $comm;

	$out_total = $total_tmp;
	$comm_t = $comm_tmp;
	push(@o_price,$out_total);	push(@i_price,$out_total);	push(@c_comm,$comm_t);	
	if ($Find_res > 0){
		$o_price = join(",",@o_price);
		$o_price = "var o_price = new Array($o_price,0);";
		$i_price = join(",",@i_price);
		$i_price = "var i_price = new Array($i_price,0);";
		$c_comm = join(",",@c_comm);
		$c_comm = "var c_comm = new Array($c_comm,0);";
		$i_select = join(",",@i_select);
		$i_select = "var i_select = new Array($i_select,0);";
		$is_lock = join(",",@lock);
		$is_lock = "var is_lock = new Array($is_lock,0);";
		print qq^<script>
		$refund_pay_info
		document.onkeydown = keyDown;
		document.onkeyup = keyup;
		function keyDown(e){
			if(event.keyCode==16){
				document.book.sh_event.value=1;
			}
		}
		function keyup(e){
			if(event.keyCode==16){
				document.book.sh_event.value=0;
			}
		}
		function Round(a_Num , a_Bit)  {
		  return( Math.round(a_Num * Math.pow (10 , a_Bit)) / Math.pow(10 , a_Bit))  ;
		}  ��
		function hide_all(){
			show('sh');hide('hd');
			$hide_all;
		}
		function show_all(){
			hide('sh');show('hd');
			$show_all;
		}
		$i_price
		$c_comm
		$o_price
		$i_select
		$is_lock
		function recount_recv(){
			var list=document.getElementsByTagName("input");
			var ii_price=[];
			for(var i=0;i<list.length && list[i];i++){
				if(list[i].type=="text" && list[i].id.indexOf('recv_account_')==0){
					var idarr=[];
					idarr=list[i].id.replace('recv_account_','').split('_');
					var i_id=idarr[0];
					if (!ii_price[i_id]){ii_price[i_id]=0;}
					ii_price[i_id]=ii_price[i_id]+Round(list[i].value,2);
					i_price[i_id]=Round(ii_price[i_id],2);
					o_price[i_id]=i_price[i_id];
				}
			}
		}
		function cal_recv(){
			var recv_total = 0;
			var comm_total = 0;
			var in_total = 0;
			var insure_total = 0;
			var insure_num = 0;
			var select_num = 0;
			var select_alert='';
			var select_resid='';
			document.getElementById("More_pay_mod").style.display = "";
			document.getElementById("mod_Pay_Recv_total").style.display = "";
			recount_recv();
			for (var j=0; j < i_select.length; j++){
				if (i_select[j] == 1 && is_lock[j]!=1) {
					comm_total = comm_total + c_comm[j];
					in_total = in_total + i_price[j];
					recv_total = recv_total + o_price[j];
					select_alert=eval("document.book.alert_status_"+j+".value");
					select_resid=eval("document.book.resia_"+j+".value");
					select_num++;
					try{
					var insure_arr = document.getElementsByName("inc_insure_num_hidden");
					if(insure_arr != null){
					    if(insure_arr.length > 0){
						    for(var m=0;m<insure_arr.length;m++){
							    var idx = insure_arr[m].getAttribute("idx");
								idx= parseFloat(idx);
								if(idx==j){
								    var num = parseFloat(insure_arr[m].value);
								    insure_num += num;
								}
							}
						}
					}
					}catch(e){
					}
				}
			}
			
			try{
			    if(document.getElementById("inc_insure_type") != null){
				    var index = document.getElementById("inc_insure_type").selectedIndex;
			        var insure_price = document.getElementById("inc_insure_type").options[index].getAttribute("data");
					if (document.getElementById("inc_insure_buy_type_1").checked) {
						insure_price=0;
					}
			        insure_total = insure_num*insure_price;
			    }
			}catch(e){
			    insure_total=0;
			}
			document.book.Comm.value = Round(comm_total,2);
			document.book.Recv_total.value = Round(in_total+insure_total,2);
			if (document.book.pay_method_num.value=='1') {
				document.book.Pay_Recv_total.value = document.book.Recv_total.value;
				if (typeof(load_ccp) == "function") {
					var ccp_total=load_ccp('getsum','');
					document.book.Pay_Recv_total.value=Round(Round(document.book.Pay_Recv_total.value,2)-Round(ccp_total,2),2);
				}
			}
			document.book.Left_total.value = Round(document.book.Total.value-recv_total,2) ;	
			if (typeof(load_ccp) == "function") {
				load_ccp('getsum','');
			}

			if(select_num == 1 && select_alert == 1){	//��ֻѡ��һ������������Ʊ��ʱ��֧����ʽĬ��ȡĸ�����һ��������¼��֧����ʽ
				\$.getJSON("/cgishell/golden/admin/manage/get_ffp.pl?callback=?",
				{User_ID:'$in{User_ID}',Serial_no:'$in{Serial_no}',Form_type:'get_pay_method',Corp_center:'$Corp_center',refund_id:select_resid},
				function(data){
					if(data["status"] == "success"){
						//alert(data['pay_object'] + "   " + data['pay_bank']);
						var pay_method=document.book.pay_method;
						for (var i = 0; i < pay_method.options.length; i++) {        
							if (pay_method.options[i].value == data['pay_object']) {        
								pay_method.options[i].selected = true;        
								break;        
							}        
						}
						if('$Pay_version'=='1'){
							changelist('list1', 'list2','0');
						}
						load_credit_payment('0');
						if(data['pay_bank'] != ''){
							var Pay_type2=document.book.Pay_type2;
							for (var i = 0; i < Pay_type2.options.length; i++) {        
								if (Pay_type2.options[i].value == data['pay_bank']) {        
									Pay_type2.options[i].selected = true;        
									break;        
								}        
							}
						}
					}else{
						alert(data["msg"]);
					}
				});	
			}
		}
		function total_insure(obj){
		    var index = obj.selectedIndex;
			var num = obj.options[index].value;
			var id = "insure_"+obj.name;
			document.getElementById(id).value = num;
			cal_recv();
		}

		function cal_debt(){
			var recv_total = 0;
			var comm_total = 0;
			var in_total = $total;
			document.book.Comm.value = recv_total;
			document.book.Recv_total.value = comm_total ;
			document.book.Left_total.value = in_total ;	
			document.book.pay_method_num.value=1;
			More_pay('');
			document.getElementById("More_pay_mod").style.display = "none";
			document.book.Pay_Recv_total.value=0;
			document.getElementById("mod_Pay_Recv_total").style.display = "none";
		}

		function call_recv(ch_id){
			for (var j=0; j < i_select.length; j++){
					if ((i_select[j] == 1) && (j <= ch_id)) {
						for (var t=j; t < ch_id; t++){
							i_select[t] = 1;
							eval("document.book.cb_"+t).checked = true;

						}
					}	
					if ((i_select[j] == 1) && (j > ch_id)) {
						for (var t=j; t > ch_id; t--){
							i_select[t] = 1;
							eval("document.book.cb_"+t).checked = true;

						}
					}	
						
				}
			if (book.all_type[0].checked){  			
				cal_recv();
			}
		}

		function ck_all(){	
			if ( document.book.t_num.value == 0 ) return; 
			$ck_all;
			if (document.book.cb.checked) {
				for (var j=0; j < i_select.length; j++){
					var cb_obj=eval("document.book.cb_"+j);
					if (cb_obj && cb_obj.disabled==false) {
						cb_obj.checked=true;
						i_select[j]=1;
					}
				}
			}
			else{
				for (var j=0; j < i_select.length; j++){	i_select[j] = 0;	}
			}
			if (book.all_type[0].checked){  
				cal_recv();
			}
			upt_Select_the();
		}
		function amountcomp(){
			var num=parseInt(document.getElementById('pay_method_num').value,10);
			var Pay_Recv_total=0;
			var Pay_Recv_Mark='';
			for (var p=0;p<num ;p++) {
				var pp='_'+p;
				if (p=='0') {
					pp='';
				}
				if (document.getElementById("list1"+pp).value=='1003.01.01' || document.getElementById("list1"+pp).value=='1003.01.02') {//POS���� fanzy2012-6-27^;
					if ($Corp_center eq "022000") {##��Ѷ��ǿ��Ҫ��������3������ͻ���Ӧ����̫����   liangby@2013-3-19
						print qq^
						if (document.getElementById("ReferNo"+pp).value == '') {
							alert("�Բ��������뽻�ײο��ţ�");
							document.getElementById("ReferNo"+pp).focus();
							document.getElementById("ReferNo"+pp).select();
							return false;
						}
						if (document.getElementById("BankName"+pp).value == '') {
							alert("�Բ��������뷢���У�");
							document.getElementById("BankName"+pp).focus();
							document.getElementById("BankName"+pp).select();
							return false;
						}
						if (document.getElementById("ReOp_date"+pp).value == '') {
							alert("�Բ��������뽻�����ڣ�");
							document.getElementById("ReOp_date"+pp).focus();
							document.getElementById("ReOp_date"+pp).select();
							return false;
						}
						if (document.getElementById("BankCardNo"+pp).value == '') {
							alert("�Բ��������뿨�ź�4λ��");
							document.getElementById("BankCardNo"+pp).focus();
							document.getElementById("BankCardNo"+pp).select();
							return false;
						}^;
					}
					print qq^
					if(document.getElementById("BankCardNo"+pp).value != '' && isNaN(document.getElementById("BankCardNo"+pp).value)){ 
						alert('���ź�4λ���������֣�') ;
						document.getElementById("BankCardNo"+pp).focus();
						document.getElementById("BankCardNo"+pp).select();
						return false;
					}
				}
				var Pay_Recv_total_p=document.getElementById("Pay_Recv_total"+pp);
				if(isNaN(Pay_Recv_total_p.value)){ 
					alert('֧����ʽ��ʵ�ս����������֣�');
					Pay_Recv_total_p.focus(); 
					return false; 
				}
				var Pay_Recv_Marks='';
				if (parseInt(Pay_Recv_total_p.value,10)<0) {
					Pay_Recv_Marks='-1';
				}else{
					Pay_Recv_Marks='1';
				}
				if (Pay_Recv_Mark=='') {
					Pay_Recv_Mark=Pay_Recv_Marks;
				}
				if (Pay_Recv_Mark!=Pay_Recv_Marks) {
					alert('֧����ʽ��ʵ�ս����ͳһ������');
					Pay_Recv_total_p.focus(); 
					return false; 
				}
				var pingzheng=document.getElementById("pingzheng"+pp);
				var pingzhenglist=document.getElementById("pingzhenglist"+pp);
				var Pay_balance=0;
				for(var i=0;i <pingzhenglist.options.length;i++){
					if (pingzheng.value==pingzhenglist.options[i].text) {
						var arr=[];arr=pingzhenglist.options[i].value.split("#");
						Pay_balance=Round(arr[1],2);
						break;
					}
				}
				if (Round(Pay_Recv_total_p.value,2)>Round(Pay_balance,2) && Pay_balance>0) {
					alert('ʹ��������������ʵ�ս��ܴ�����������');
					Pay_Recv_total_p.focus(); 
					return false; 
				}
				Pay_Recv_total=Pay_Recv_total+Round(Pay_Recv_total_p.value,2);
			}
			if ( document.book.t_num.value == 0 ) return;
			if(isNaN(document.book.Recv_total.value)){ 
				alert('�����������֣�') 
				document.book.Recv_total.focus(); 
				return false; 
			}
			Pay_Recv_total=Round(Pay_Recv_total,2);
			if (document.getElementById("sxk_credit")) {
				var sxk_credit=Round(document.getElementById("sxk_credit").value,2);
				Pay_Recv_total=Round(Pay_Recv_total-sxk_credit,2);
			}
			if (typeof(load_ccp) == "function") {
				var ccp_total=load_ccp('getsum','');
				if (ccp_total===false) {
					return false;
				}
				Pay_Recv_total=Round(Round(Pay_Recv_total,2)+Round(ccp_total,2),2);
			}
			if (Pay_Recv_total!=document.book.Recv_total.value) {
				alert('֧����ʽ��ʵ�ս��֮��'+Pay_Recv_total+'������ѡ�ж�������ʵ�պϼ�'+document.book.Recv_total.value+'��');
				document.getElementById('Pay_Recv_total').focus(); 
				return false; 
			}
			var conret=confirm("ȷ���ύ?");
			if (conret==false) {
				return;
			}
			var rst ;
			var is_sxk=document.getElementById("is_sxk").value;
			if(is_sxk == "Y"){		//������ͻ��Ӹ�����
				rst=confirm("�ÿͻ�Ϊ������ͻ�����ȷ��֧����ʽ�Ƿ���ȷ?");
				if(rst==false){
					return;
				}
			}
			var need_count=document.getElementById("need_count").value;
			if(need_count != '' &&  need_count != Pay_Recv_total){		//�˵������ʵ�ս��ȼӸ�����
				rst=confirm("�˵����������ʵ�ս��ȣ���ȷ���Ƿ��������?");
				if(rst==false){
					return;
				}
			}
			var ret;
			for (var j=0; j < i_select.length-1; j++){
				if (i_select[j] == 1 && eval("document.book.cb_"+j+".checked")) {
					if (is_lock[j] == 1) {
						ret = 1;	
					}			
				}
			}
			if(ret == 1){ 
				var rst ;
				rst=confirm("ѡ�еĶ�����δ��ҵģ�ȷ������������?");
				if(rst==true){
					if (book.all_type[0].checked){  
						document.book.act.value = 1; 
					} 
					if (book.all_type[1].checked){  
						document.book.act.value = 2; 
					} 
				 document.book.submit();
				}else{
					return;
				}
			 }
			 document.book.btok.disabled=true;
			 if (book.all_type[0].checked){  
				document.book.act.value = 1; 
			 } 
			 if (book.all_type[1].checked){  
				document.book.act.value = 2; 
			 } 
			 document.book.submit();			 
		}
		function load_Select_the(){
			if (i_select.length<1) {return;}
			var Select_the_ex=[];
			Select_the_ex=document.query.Select_the.value.split(",");
			if (Select_the_ex.length<1) {return;}
			var Select_the={};
			for (var i=0;i<Select_the_ex.length ;i++) {
				var Selectthe=Select_the_ex[i];
				Select_the[Selectthe]="Y";
			}
			for (var j=0; j < i_select.length-1; j++){
				var cb_obj=eval("document.book.cb_"+j);
				if (cb_obj && Select_the[cb_obj.value]=="Y" && cb_obj.disabled==false) {
					cb_obj.checked=true;
					i_select[j]=1;
				}
			}
			if (book.all_type) {
				if (book.all_type[0].checked){  
					cal_recv();
				}
			}
			upt_Select_the();
		}
		function upt_Select_the(){
			if (i_select.length<1) {return;}
			var Select_the_arr=[];
			for (var j=0; j < i_select.length-1; j++){
				if (i_select[j]==1) {
					var cb_obj=eval("document.book.cb_"+j);
					if (cb_obj.disabled==false && cb_obj.checked==true) {
						Select_the_arr.push(cb_obj.value);
					}
				}
			}
			var Select_the=Select_the_arr.join(',');
			document.query.Select_the.value=Select_the;
		}
		function addLoadEvent(func) {
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
		addLoadEvent(load_Select_the);
		</script>^;	
		&sum_account($ii,'Y');
		print qq!</table></div><div class="clear"></div>!;
		if ($query_only ne "Y" &&($op == 2 ||$op == 0 || $op == 3 || $op == 4 || $op == 5) && $in{History} ne "Y"){##����ͨ���ͻ���ѯʱ��������������     liangby@2008-6-17
			#$pay_list = "<option value='' selected >��ѡ��֧����ʽ";
			$sql = "select Pay_method,Pay_name from ctninfo..d_paymethod 
				where Is_payed='Y' and Is_netpay='N' and Is_show='Y' and Corp_ID in ('SKYECH','$Corp_center')
				order by Order_seq ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						if ($row[0] eq "C") {
							$pay_list .= "<option value='$row[0]' selected> $row[1]</option>";
						}
						else{
							$pay_list .= "<option value='$row[0]'> $row[1]</option>";
						}
					}
				}
			}

			if ($in{all_type} eq "S" || $in{all_type} eq "") {  ##����Ƿ�� likunhua@2009-02-26
				$c_shou="checked";
			}
			elsif ($in{all_type} eq "Q") {
				$c_qian="checked";
			}
			#<select name=pay_method style=width:100px>$pay_list</select>
			if ($Corp_center eq "022000") {##��ѶĬ��ѡ���ջط�Ʊ   liangby@2012-10-17
				$ck_is_voucher=" checked";
			}
			my $sxk_event=($sxk_credit eq "Y")?" onpropertychange='sxk_event();' onblur='sxk_event();' onchange='sxk_event();'":'';
			my $sxk_html=($sxk_credit eq "Y")?"<label id='mod_sxk_credit'>ת�������<input type=text id='sxk_credit' name='sxk_credit' class=grayline readonly style='color:blue' size=6 value=0>��</label>":'';
			print qq`
			<div class="operating" >
				<div class="operating_button">
					<table width="100%" border="0" cellspacing="0" cellpadding="1">
						<tbody>`;
							if($Corp_center eq "CZZ259"){## �޸ı������� dingwz@2014-06-16
								my $inc_insure_list = &inc_insure_list();
								print qq`
								<tr>
									<td style="border-bottom-color:#ddd;border-bottom-width:1px;border-bottom-style:dashed;height:20px;">
										<font color='red'>�޸ı��գ�</font>
										<label><input id='inc_insure_buy_type_0' type='radio' value='0' name='inc_insure_buy_type' checked='checked' onclick="cal_recv()" class="radio_publish"/>����</label>
										<label><input id='inc_insure_buy_type_1' type='radio' value='1' name='inc_insure_buy_type' onclick="cal_recv()" class="radio_publish"/>����</label>
										<label>��������:<select id='inc_insure_type' name='inc_insure_type' class="input_txt_select input_txtgy" onchange="cal_recv()" >$inc_insure_list</select></label>
									</td>
								</tr>`;
							}
							if ($op == 0 ){ ##δ����
								$t_bt = "�������ͣ�<label><input type=radio name='all_type' value='S' onclick='cal_recv();' $c_shou class='radio_publish'>��������</label>&nbsp;<label><input type=radio name='all_type' value='Q' onclick='cal_debt();' $c_qian class='radio_publish'>����Ƿ��</label>��";
							}
							elsif ($op == 2 ){ ## ������ Ƿ��
								$t_bt = "�������ͣ�<label><input type=radio name='all_type' value='S' checked class='radio_publish'>��������</label>&nbsp;<label style='display:none'><input type=radio name='all_type' value='Q' class='radio_publish'>����Ƿ��</label>��";
							}
							elsif ($op == 3 ){ ## �ѳ�Ʊ δ�� 
								$t_bt = "�������ͣ�<label><input type=radio name='all_type' value='S' class='radio_publish'>��������</label>&nbsp;<label><input type=radio name='all_type' value='Q' checked class='radio_publish'>����Ƿ��</label>��";
							}
							elsif ($op == 4 ){ ## ������ ��δ�� 
								$t_bt = "�������ͣ�<label><input type=radio name='all_type' value='S' checked class='radio_publish'>����������</label>&nbsp;<label style='display:none'><input type=radio name='all_type' value='Q' class='radio_publish'><font color=red>����Ƿ�˿�</font></label>";
							}
							elsif ($op == 5 ){ ## δ�˿�
								$t_bt = "�������ͣ�<label><input type=radio name='all_type' value='S' checked class='radio_publish'>�����˿�</label>&nbsp;<label><input type=radio name='all_type' value='Q'><font color=red class='radio_publish'>����Ƿ�˿�</label>";
							}
							$t_bt .= qq!<label><input type="checkbox" name="cb" onclick="ck_all();" class="radio_publish"><font style='font-size:9pt;'>ѡ��ȫ��</font></label>!;
							my $Operate_date_js=(($Function_ACL{CWSY}&(1<<0)) != 0)?qq` onfocus="WdatePicker({dateFmt:'yyyy.MM.dd',skin:'whyGreen',maxDate:'$today'});"`:"";
							print qq`
							<tr>
								<td>
									<script defer="defer" language="text/javascript" type="text/javascript" src="/admin/gate/js/My97DatePicker/WdatePicker.js"></script>
									<table width="100%" border="0" cellspacing="0" cellpadding="2">
										<tbody>
											<tr bgcolor="#f9fafc">
												<td>
													$t_bt													
													<input name="btok" type="button" class="btn30" onclick='amountcomp()' value="ȷ���ύ" />
													<input name="" type="reset" class="btn31" value="����" />
													<input type=hidden name=Guest_name value='$in{Guest_name}'><input type=hidden name=PNR value='$in{PNR}'>
													<input type=hidden name=Corp_ID value='$in{Corp_ID}'><input type=hidden name=Sender value='$in{Sender}'>
													<input type=hidden name=Pay_method value='$in{Pay_method}'><input type=hidden name=Op value=$op>
													<input type=hidden name=Depart_date value='$Depart_date'><input type=hidden name=End_date value='$End_date'>
													<input type=hidden name=User_ID value='$in{User_ID}'><input type=hidden name=Serial_no value='$in{Serial_no}'>
													<input type=hidden name=sh_event value=0><input type=hidden name=user_book value='$in{user_book}'>
													<input type=hidden name=Res_ID value='$in{Res_ID}'><input type=hidden name=act value=0>
													<input type=hidden name=num value=$w><input type=hidden name=t_num value=$i>
													<input type=hidden name=tkt_id value='$in{tkt_id}'>	
													<input type=hidden name=is_sxk id=is_sxk value=''>
													<input type=hidden name=need_count id=need_count value='$in{need_count}'>
												</td>
												<td>
													��������&nbsp;<input name="Operate_date" id="Operate_date" type="text" class="input_txt input_txt70" style='color:blue;width:70px;' maxlength="10" value="$today" $Operate_date_js readonly="readonly"/>
													ѡ��ʵ��&nbsp;<input name="Recv_total" id="Recv_total" type="text" class="input_txt input_txt70" style='color:blue;width:60px;' value="0" readonly="" $sxk_event/>
													<input type='hidden' value='0' id='input_insure_total' />
													��Ӷ��<input name="Comm" type="text" class="input_txt input_txt70" style='color:blue;width:60px;' value="0" readonly="" />
													<span id="ccptb" style="display:none;">����ȯ�ֿۣ�<input type=text id='ccp_total' name='ccp_total' class="input_txt input_txt70;" readonly style='color:blue;width:60px;' value=0></span>
													��$sxk_html
													<b class=" red">δ���㣺<input name="Left_total" type="text" class="input_txt input_txt70" style='color:red;width:60px;' value="$total" readonly="" /><input type=hidden name=Total value='$total'></b>
													<label><input type="checkbox" name="Is_voucher" id='Is_voucher' value='S' $ck_is_voucher class="radio_publish"><b class=" red">�˷�Ʊ���ջط�Ʊ</b><label>
												</td>
											</tr>
										</tbody>
									</table>
								</td>
							</tr>`;
							my $paymaxnum=30;#֧����ʽ�������3��
							my $more_btn=qq!<td>
									<span id="More_pay_mod"><nobr>
										<input name="" type="button" class="btn32" value="��ӷ�ʽ" onclick="More_pay('add');"/>
										<input name="" type="button" class="btn32" value="���ٷ�ʽ" onclick="More_pay('del');"/></nobr>
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
													<label>֧����ʽ��<select id="list1$pp" name='pay_method$pp' class="input_txt_select input_txtgy" style='width:130pt;' onchange="if('$Pay_version'=='1'){changelist('list1', 'list2','$p');};load_credit_payment('$p');"></select></label>
													<label>ƾ֤�ţ�<input type=text value='' id='pingzheng$pp' name='pingzheng$pp' class="input_txt input_txt70" style='width:100px;position:relative;z-index:10;' onchange="tradeno_verifys('$pp');">
															<select id='pingzhenglist$pp' name='pingzhenglist$pp' class="input_txt_select input_txtgy" style="height:18px;position:absolute;margin-top:0px;margin-left:-110px;width:124px;z-index:2;" onchange="change_cmt('pingzhenglist$pp', 'pingzheng$pp','Pay_balance$pp')" onclick="if(this.options.length==1){change_cmt('pingzhenglist$pp', 'pingzheng$pp','Pay_balance$pp');}"></select>
													</label>
													<label id="mod_Pay_Recv_total$pp">&nbsp;&nbsp;ʵ�գ�<input type=text id="Pay_Recv_total$pp" name="Pay_Recv_total$pp" class="input_txt input_txt70" style='color:blue;width:40pt;' value=0 $sxk_event></label>
													<label>��<span id="Pay_balance$pp"></span></label>
												</td>
												$more_btn
											</tr>
											<tr>
												<td height=20 colspan=2>
													<label id='list2_lb$pp'>������Ŀ��<select id="list2$pp" name='Pay_type2$pp' class="input_txt_select input_txtgy" style='width:130pt;' onchange="load_credit_payment('$p');"></select></label>
													<label id='list3$pp'>���ײο��ţ�<input type="text" id="ReferNo$pp" name="ReferNo$pp" maxlength=16 class="input_txt input_txt70" value="">
														�����У�<input type="text" id="BankName$pp" name="BankName$pp" maxlength=8 class="input_txt input_txt70" value="">
														�������ڣ�<input type=text id="ReOp_date$pp" name="ReOp_date$pp" class="input_txt input_txt70" readonly maxlength=10 value='' onclick="event.cancelBubble=true;ShowCalendar(document.book.ReOp_date$pp,document.book.ReOp_date$pp,null,0,330)">
														���ź�4λ��<input type="text" id="BankCardNo$pp" name="BankCardNo$pp" class="input_txt input_txt70" maxlength=4 value="">
													</label>
												</td>
											</tr>
										</table>
									</td>
								</tr>`;
							}
							print qq`
							<input type='hidden' name='pay_method_num' id='pay_method_num' value='1'/>
							<input type='hidden' name='pay_method_maxnum' id='pay_method_maxnum' value='$paymaxnum'/>`;
							
							my $r_ck;
							if ($Corp_center eq "CGQ147") {	$r_ck=" checked";	}
							print qq`							
							<tr>
								<td bgcolor="#f9fafc">
									<table width="100%" border="0" cellspacing="0" cellpadding="0">
										<tbody>
											<tr>
												<td width="70" rowspan="2">������ע��</td>
												<td rowspan="2"><textarea name="Comment" maxlength=128 cols="" rows="" class="input_txt " style=" width:100%;height:50px;"></textarea></td>
												<td width="400" style="padding-left:14px;"><b class="red"><strong>��Shift�����ѡ���ɽ��ж�ѡ��δ��ҡ���ʷ��������������!</strong></b><br /> <b class="red"><strong>(ע��:�ڴ˽���ά����ע��,��ѡ������ע���ᱻ�滻)</strong></b><br /></td>
											</tr>
											<tr>
												<td valign="top" style="padding-left:14px;">
													<label class="search_for_term"><input type="checkbox" name="is_rmk" value="Y" $r_ck/>��ע����ǩע��</label>
													<label class="search_for_term"><input type="checkbox" name="is_shows" value="Y"/>ǩע��ʾ�����͵�</label>
												</td>
											</tr>
										</tbody>
									</table>
								</td>
							</tr>
						</tbody>
					</table>
				</div>
			</div>
			<script type="text/javascript">
				var payhash=[];
				var datalist = [$array_list];
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
				function sxk_event(){
					if (!document.book.sxk_credit) {
						return;
					}
					if (typeof(load_ccp) == "function") {
						var ccp_total=load_ccp('getsum','');
						if (ccp_total>0) {
							sxk_credit.value=0;
							return;
						}
					}
					var pay_method_num=parseInt(document.book.pay_method_num.value,10);
					var sxk_credit=document.book.sxk_credit;
					var mod_sxk_credit=document.getElementById('mod_sxk_credit');
					if (document.book.all_type[0].checked==true) {
						mod_sxk_credit.style.display = "";
						var Pay_Recv_total=0;
						for (var p=0;p<pay_method_num ;p++) {
							var pp='_'+p;
							if (p=='0') {
								pp='';
							}
							Pay_Recv_total=Pay_Recv_total+Round(document.getElementById("Pay_Recv_total"+pp).value,2);
						}
						var sxk_credits=Round(Round(Pay_Recv_total,2)-Round(document.getElementById('Recv_total').value,2),2);
						if (sxk_credits<0) {sxk_credits=0;}
						sxk_credit.value=sxk_credits;
						return;
					}else{
						sxk_credit.value=0;
						mod_sxk_credit.style.display = "none";
						return;
					}
				}
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
						if (pid == '' && datalist[i][4] != '0')	{	// ���ʽ
							continue;
						}
						if (array_exists(exists_value, datalist[i][1]))	// �����ظ��������б�
						{
							continue;
						}
						list[list.options.length] = new Option(datalist[i][2], datalist[i][1]);
						exists_value.push(datalist[i][1]);	// д����������������ж��ظ�
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
					if (pid=='1003.01.01' || pid=='1003.01.02') {//POS�����������п��ŵ�fanzy2012-6-27
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
					if ("$sxk_credit"=="Y" && "$in{Op}"=="5") {
						if (!src) {
							obj.value="1003.02.25";
						}
					}
				}
				var removeAll = function(obj)
				{
					obj.options.length = 0;
				}
				//�������Ԫ���Ƿ����
				function array_exists(arr, item)
				{
					for (var n = 0; n < arr.length; n++)
					if (item == arr[n]) return true;
					return false;
				}
				for (var i=0;i<parseInt(document.getElementById("pay_method_maxnum").value,10) ;i++) {
					changelist('', 'list1',i);
					changelist("list1","list2",i);
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
			</script>`;
		}
	}else{
		print qq!</table><h3 class="tishi">û�з������������ݡ�</h3></div><div class="clear"></div>!;
	}
	print qq!</form>!;
	if ($Total_num > $records) {
		print "<table border=0 cellpadding=2 cellspacing=0 width=100%>
		<tr><td>���� $Total_num ��������</td>
		<td align=right>";
		## ----------------------------- start of page control ----------------------------- 
		&page_control_new($Total_num,$records,$Start,10);
		##  ----------------------------- end of page control ------------------------------ 
		print "</tr></table>";
	}
	$pay_ment_corp=$in{Corp_ID};
	if ($pay_ment_corp eq "") {
		@res_corpids=keys %res_corpids;
		if (scalar(@res_corpids)==1) {
			$pay_ment_corp=$res_corpids[0];
		}
		
	}
	if ($pay_ment_corp ne $Corp_center && $pay_ment_corp ne "") {##��ȡ���������   liangby@2015-6-11
		
		print qq`
		<div class="wrapper" id="auto_process"></div>
			<div id="payment_show" style="background:#f4f4f4; border-top: #ff6600 solid 1px;width:550px;height:200px;overflow:auto;overflow-x:hidden;display:none;" ></div>
		`;
		print qq`<script language=javascript>
			function get_credit_payment(){
				document.getElementById('auto_process').innerHTML='���ڻ�ȡ��������Ϣ�����Ժ򡭡���';
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
									html_str="<br /><table  border=1 bordercolor=808080 width=500 bordercolordark=FFFFFF cellpadding=0 cellspacing=0  ><tr><td colspan=4>�ͻ�(<b>$pay_ment_corp</b>)�����������ϸ</td></tr><tr bgcolor=f2f2f2 height=30 ><td>�����Ŀ</td><td>���������Ŀ</td><td>ƾ֤��</td><td>���</td></tr>"+html_str+"</table>";
									document.getElementById("payment_show").style.display="";
									document.getElementById("is_sxk").value="Y";
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
							document.getElementById('auto_process').innerHTML = '�����������ʾ��'+data['message']+" <input type='button' id='ticketing_rest' value='���²�ѯ������' title='���²�ѯ������' class='btn30' onmouseover=\\"this.className='btn31'\\" onmouseout=\\"this.className='btn30'\\" onclick=\\"get_credit_payment();\\" />";
						}
					},
					error: function(XMLHttpRequest, textStatus, errorThrown){
						var textStatus_str=textStatus;
						if (textStatus=="timeout") {
							textStatus_str="���糬ʱ,���Ժ�����";
						}else if (textStatus=="error") {
							textStatus_str="��̨����������";
						}
						document.getElementById('auto_process').innerHTML = '�����������ʾ��'+textStatus_str+" <input type='button' id='ticketing_rest' value='���²�ѯ������' title='���²�ѯ������' class='btn30' onmouseover=\\"this.className='btn31'\\" onmouseout=\\"this.className='btn30'\\" onclick=\\"get_credit_payment();\\" />";;
						
						
					}
				});
				
			}
			get_credit_payment();
			</script>`;
	}
	if ($query_only ne "Y" && $Find_res == 1 && $jump_w ne "" && ($op == 0 || $op == 2 || $op == 3 || $op == 4 || $op == 5)) {
	  print qq!<script>$jump_w</script>!;
    }
	if ($ccptd{resid} ne "" && $ccptd{userid} ne "") {#����ȯ	fanzy@2016-02-23
		my $CCP_used_last="";
		my $cCCP_voucher="";
		my $HCityR="";
		if ($ccptd{Book_type}==0) {
			$HCityR=$HCityRs[0];#����ȡ��һ��
		}elsif($ccptd{Book_type}==1){
			my $lsm=sprintf("%.0f",(scalar(@HCityRs)/2)-1);
			$HCityR=$HCityRs[$lsm];#����ȡƽ�����м�һ��
		}else{
			$HCityR=$HCityRs[-1];#����ȥ���һ��
		}
		my %HCityR_info=&get_City_info($HCityR);
		$ccptd{discount}=sprintf("%.2f",$ccptd{discount}*10);
		$ccptd{agttotal}=sprintf("%.2f",$ccptd{agttotal});
		my $sql_ccp="select CCP_no,Amount,Inter_area_ids,NotPtype
			from ctninfo..CCP_voucher
			where Sales_ID='$Corp_center'
				and User_ID='$ccptd{userid}'
				and Status='Y' \n";
				if ($ccptd{Air_type} eq "N") {
					$sql_ccp.=" and BP_type like '%A%' \n";
				}else{
					$sql_ccp.=" and BP_type like '%Y%' \n";
				}
				$sql_ccp.=" and Bfrom like '%$ccptd{Net_book}%'
				and Start_date<='$today'
				and End_date>='$today'
				and (Lt_res_samount=null or Lt_res_samount=0 or Lt_res_samount<=$ccptd{agttotal})
				and (Lt_res_eamount=null or Lt_res_eamount=0 or Lt_res_eamount>=$ccptd{agttotal}) ";
		if ($ccptd{discount} >0) {##�����ۿ�Ϊ0�Ķ���
			$sql_ccp .= " and (NotDis=null or NotDis<$ccptd{discount}) "; 
		}
		$sql_ccp .=" order by End_date,Amount desc,Op_time \n";
		#if ($in{User_ID} eq "admin") {
			#print "<Pre>$sql_ccp";
		#}
		$db->ct_execute($sql_ccp);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					my $Inter_area_idsoff="";
					if ($row[2] eq "") {
						$Inter_area_idsoff="Y";
					}else{
						foreach (split(/\,/,$row[2])){
							if ($HCityR_info{Inter_area_id}==$_) {
								$Inter_area_idsoff="Y";
							}
						}
					}
					if ($Inter_area_idsoff eq "Y") {
						my $Ptype="A";
						if ($row[3]!~/C/) {
							$Ptype.="C";
						}
						if ($row[3]!~/B/) {
							$Ptype.="B";
						}
						if ($cCCP_voucher ne "") {$cCCP_voucher.=",";}
						$cCCP_voucher.=qq`{"CCP_no":"$row[0]","Amount":$row[1],"Ptype":"$Ptype"}`;
					}
				}
			}
		}
		if ($cCCP_voucher ne "") {
			##����Ƿ����ô����
			$sql_tt=" select CCP_no,P_no from ctninfo..CCP_voucher where Sales_ID='$Corp_center' 
				and User_ID='$ccptd{userid}' and Res_ID='$ccptd{resid}' ";
			my @old_ccp_no=();
			$db->ct_execute($sql_tt);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT) {
					while(@row = $db->ct_fetch) {
						push(@old_ccp_no,$row[0]);
					}
				}
			}
			my $old_ccp_no=join("','",@old_ccp_no);
			if ($old_ccp_no ne "") {
				$sql_tt=" select Last_name,Pay_string,Recv_total,User_ID,convert(char(10),Operate_time,102)+''+convert(char(8),Operate_time,108),Comment from ctninfo..Airbook_pay_$Top_corp where Reservation_ID='$ccptd{resid}' and Pay_object='4003.01.03' and Recv_total>0 and Pay_string in ('$old_ccp_no') ";
				$db->ct_execute($sql_tt);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT) {
						while(@row = $db->ct_fetch) {
							if ($CCP_used_last ne "") {$CCP_used_last.=",";}
							$CCP_used_last.=qq`"$row[0]":["$row[1]","$row[2]","$row[3]","$row[4]","$row[5]"]`;
						}
					}
				}
			}
		}
		if ($CCP_used_last ne "" || $cCCP_voucher ne "") {
			$ccptd{num}=sprintf("%.2f",$ccptd{num});
			print qq`
			<script type="text/javascript">
				var CCP_voucher=[$cCCP_voucher];//����ȯ
				var CCP_used_last = {$CCP_used_last};//��ʹ�ù�����ȯ���ÿ�
				function load_ccp(type,sno){
					if (type=="sum" || type=="getsum") {
						var ccp_total=0;
						var ccp_Repeat={};
						for (var i=0;i<=parseInt("$ccptd{num}",10) ;i++) {
							if (document.getElementById("ccpid_"+i) && document.getElementById("cb_0").disabled==false && document.getElementById("cb_0").checked==true) {
								var ccp_no=document.getElementById("ccpid_"+i).value;
								if (ccp_no!="") {
									if (ccp_Repeat[ccp_no]=="Y") {
										alert("����ȯ�ظ���");
										document.getElementById("ccpid_"+i).focus();
										return false;
									}else{
										ccp_Repeat[ccp_no]="Y";
									}
									var Amount=load_ccp("getmoney",ccp_no);
									if (!Amount) {
										alert("����ȯ����");
										document.getElementById("ccpid_"+i).focus();
										return false;
									}
									var recv_account=document.getElementById("recv_account_0_0_"+i).value;
									if (Round(Amount,2)>Round(recv_account,2)) {
										alert("����ȯ������Ӧ�ս�");
										document.getElementById("ccpid_"+i).focus();
										return false;
									}
									ccp_total+=Amount;
								}
							}
						}
						document.book.ccp_total.value=ccp_total;
						if (type=="sum") {
							cal_recv();
						}
						return ccp_total;
					}else if(type=="getmoney"){
						for (var p=0;p<CCP_voucher.length ;p++) {
							if (CCP_voucher[p]["CCP_no"]==sno) {
								return parseInt(CCP_voucher[p]["Amount"],10);
							}
						}
					}else{
						document.getElementById("ccptb").style.display='';
						for (var i=0;i<=parseInt("$ccptd{num}",10) ;i++) {
							document.getElementById("ccptdto_"+i).style.display='';
							var ccptd=document.getElementById("ccptd_"+i);
							var idarr=[];idarr=ccptd.getAttribute("data").split(',');//Last_name,Passage_type
							if (CCP_used_last[idarr[0]]) {
								ccptd.innerHTML="����ȯ��<span style='text-decoration:line-through;color:gray;margin-left:5px;' title='����ȯ�ţ�"+CCP_used_last[idarr[0]][0]+"\\n�ֿ۽�"+CCP_used_last[idarr[0]][1]+"\\n�� �� Ա ��"+CCP_used_last[idarr[0]][2]+"\\n����ʱ�䣺"+CCP_used_last[idarr[0]][3]+"\\n������ע��"+CCP_used_last[idarr[0]][4]+"'>"+CCP_used_last[idarr[0]][0]+"��&#65509 "+CCP_used_last[idarr[0]][1]+"</span>";
							}else{
								if (document.getElementById("cb_0").disabled==false && CCP_voucher.length>0) {
									ccptd.innerHTML="����ȯ��<select name='ccpid_"+i+"' id='ccpid_"+i+"' class='input_txt_select input_txt280'></select>";
									var ccpid=document.getElementById("ccpid_"+i);
									ccpid.options.length = 0;
									ccpid.options.add(new Option(" -- ��ѡ��Ҫ�ֿ۵Ĵ���ȯ -- ",""));
									for (var p=0;p<CCP_voucher.length ;p++) {
										if (CCP_voucher[p]["Ptype"].indexOf(idarr[1])>=0) {
											ccpid.options.add(new Option(CCP_voucher[p]["CCP_no"]+"����"+CCP_voucher[p]["Amount"],CCP_voucher[p]["CCP_no"]));
										}
									}
									ccpid.onchange=function(){load_ccp('sum','');}
								}
							}
						}
					}
				}
				addLoadEvent(load_ccp);
			</script>`;
		}
	}
}
## =====================================================================
## ��ƺ��� 
## =====================================================================
sub air_ban{
	local($op)=@_;
	## ---------------------------------------------------------------------
	&show_air_js();
	if ($op eq "6") {
		$in{ckeck_rmk}="Y";
	}
	$sql = "select Air_parm from ctninfo..Corp_extra where Corp_ID='$Corp_center' "; 
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$Air_parm=$row[1];
			}
		}
	}
	##��ȡ����Ա��Ϣ  liangby@2016-3-27
	&get_userinfos("","S','O','Y","");
	print "<table align=center border=1 bordercolor=808080 width=100% bordercolordark=FFFFFF cellpadding=0 cellspacing=0>
	<tr align=center bgcolor=f2f2f2 height=30 >
	<form action='air_ban.pl' method=post name=book>
	<td>ѡ��</td>
	<td height=19>��Ʊ����</td>
	<td>�ͻ�</td>
	<td>����Ա</td>
	<td>��������</td>
	<td>����</td>
	<td>״̬</td>
	<td>Ʊ֤��Դ</td>
	<td>Ʊ֤</td>
	<td>֧������</td>
	<td>��Ʊ����</td>
	<td>Ʊ��</td>
	<td>��������</td>
	<td>����</td>
	<td>����</td>
	<td>�ִ�</td>
	<td>�����</td>
	<td>��λ</td>
	";
	my $in_price_name="�����";
	if ($in{air_type} eq "Y") {
		$scny_str="<td width=40>SCNY</td>";
		$in_price_name="����";
	}else{	
		$scny_str="";	
	}
	if ($op == 0 or $op == 1 or $op == 7 or $op == 8) {
		print "<td>����</td>";
	}
	else{
		print "<td>������</td>";
	}
	print "<td>Ʊ���</td>";
	if ($in{air_type} eq "Y") {
		print "<td width=40>SCNY</td>
		<td>����˰</td>
		<td>˰��</td>";
	}else{
		print qq!<td width=40>�������</td>
			<td>����ȼ��</td>
			<td>����</td>
			<td>ȼ��</td>!;
	}
	print "<td width=40>$in_price_name</td>
	<td>�����</td>
	<td>ë��</td>
	<td>�����</td>
	
	<td>����С��</td>";
	if ($in{ckeck_rmk} eq "Y") {
		print "<td>������</td><td>����ʱ��</td>";
	}
	print "</tr><tr><td height=1></td></tr>";

	if ($in{datadown} eq "Y") {
		my $iCol=0;
		$worksheet->write_string($iRow,$iCol,"��Ʊ����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�ͻ�",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����Ա",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"��������",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"״̬",$format1);$iCol=$iCol+1;  	 
		$worksheet->write_string($iRow,$iCol,"Ʊ֤��Դ",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"Ʊ֤",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"��Ʊ����",$format1);$iCol=$iCol+1;
		$worksheet->write_string($iRow,$iCol,"Ʊ��",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"��������",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1;
		$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�ִ�",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"��λ",$format1);$iCol=$iCol+1; 
		if ($op == 0 or $op == 1 or $op == 7 or $op == 8) {
			$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1; 
			$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1; 
		}
		else{
			$worksheet->write_string($iRow,$iCol,"������",$format1);$iCol=$iCol+1; 
		}
		if ($in{air_type} eq "Y") {
			$worksheet->write_string($iRow,$iCol,"SCNY",$format1);$iCol=$iCol+1; 
			$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1; 
		}else{
			$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol=$iCol+1;
		}
		$worksheet->write_string($iRow,$iCol,"ͬ�м�",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"Ʊ���",$format1);$iCol=$iCol+1; 
		if ($in{air_type} eq "Y") {
			$worksheet->write_string($iRow,$iCol,"����˰",$format1);$iCol=$iCol+1; 
			$worksheet->write_string($iRow,$iCol,"˰��",$format1);$iCol=$iCol+1; 
		}else{
			$worksheet->write_string($iRow,$iCol,"�������˰",$format1);$iCol=$iCol+1; 
			$worksheet->write_string($iRow,$iCol,"����ȼ��˰",$format1);$iCol=$iCol+1; 
			$worksheet->write_string($iRow,$iCol,"����˰",$format1);$iCol=$iCol+1; 
			$worksheet->write_string($iRow,$iCol,"ȼ��˰",$format1);$iCol=$iCol+1; 
		}
		$worksheet->write_string($iRow,$iCol,"��Ӷ",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"ë��",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol=$iCol+1;  
		$worksheet->write_string($iRow,$iCol,"����С��",$format1);$iCol=$iCol+1; 
		if ($in{ckeck_rmk} eq "Y") {
			$worksheet->write_string($iRow,$iCol,"������",$format1);$iCol=$iCol+1; 
			$worksheet->write_string($iRow,$iCol,"����ʱ��",$format1);$iCol=$iCol+1; 
		}
	
		$iRow=$iRow+1;
	}

	## define table tailer
	sub sum_ban{
		local($l_type) = @_;
		print "<tr align=right>";
		if ($op == 0 or $op == 1 or $op == 7 or $op == 8) {
			print "<td height=20 colspan=19 align=right ><b>�ܼƣ���Ʊ $CTk_num �ţ���</td>";
		}
		else{
			print "<td height=20 colspan=19 align=right><b>�ܼƣ���Ʊ $CTk_num �ţ���</td>
			<td>$CReturn_price</td>";
		}
		$CIn_price = sprintf("%.2f",$CIn_price);
		$COut_price = int($COut_price);
		$CProfit = sprintf("%.2f",$CProfit);
		$CService_fee = sprintf("%.2f",$CService_fee);
		$CProfit = sprintf("%.2f",$CProfit);
		$CSCNY_price=sprintf("%.2f",$CSCNY_price);
		$CI_total=sprintf("%.2f",$CI_total);
		$Cagency_fee=sprintf("%.2f",$Cagency_fee);
		if ($in{air_type} eq "Y") {
			print "<td>$COut_price</td>
			<td>$CSCNY_price</td>
			<td>$CTax</td>
			<td>$CTax_G</td>";
		}
		else{
			print "<td>$COut_price</td>
			<td>$CTax</td>
			<td>$CYQ</td>
			<td>$CTax_G</td>
			<td>$CYQ_G</td>";
		}
		print "
			<td>$CIn_price</td>
			<td>$Cagency_fee</td>
			<td>$CProfit</td>
			<td>$CService_fee</td>
			<td>$CI_total</td>
			</tr>
		</table>";

		if ($in{air_type} eq "Y") {
			$a_icol=16;
			$b_icol=15;
		}else{
			$a_icol=17;
			$b_icol=16;		
		}
		if ($in{datadown} eq "Y") {
			if ($op == 0 or $op == 1 or $op == 7 or $op == 8) {
				$worksheet->merge_range($iRow,0,$iRow,$a_icol,"�ܼƣ���Ʊ $CTk_num �ţ���",$format1);
				$iCol=$a_icol;
			}
			else{
				$worksheet->merge_range($iRow,0,$iRow,$b_icol,"�ܼƣ���Ʊ $CTk_num �ţ���",$format1);
				$iCol=$b_icol;
				$worksheet->write_number($iRow,$iCol,$CReturn_price,$format1);	$iCol=$iCol+1;
			}
			if ($in{air_type} eq "Y") {
				$worksheet->write_number($iRow,$iCol,$CSCNY_price,$format1);	$iCol=$iCol+1;
			}
			$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$CIn_price,$format1);		$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$COrigin_price,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$COut_price,$format1);	$iCol=$iCol+1;
			if ($in{air_type} eq "Y") {
				$worksheet->write_number($iRow,$iCol,$CTax,$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$CTax_G,$format1);	$iCol=$iCol+1;
			}else{
				$worksheet->write_number($iRow,$iCol,$CTax,$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$CYQ,$format1);	$iCol=$iCol+1;	
				$worksheet->write_number($iRow,$iCol,$CTax_G,$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$CYQ_G,$format1);	$iCol=$iCol+1;	
			}
			$worksheet->write_number($iRow,$iCol,$Ccomm,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$Cagency_fee,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$CProfit,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$CService_fee,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$CI_total,$format1);	$iCol=$iCol+1;
			$iRow=$iRow+1;
		}
	}
	## ---------------------------------------------
	## ���ڼ��
	## ---------------------------------------------
	if(&date_check($Depart_date)==0){
		return "</td><td align=right><font color=red>������ʾ�����鿪ʼ���������Ƿ���ȷ��</td></tr>";
	}
	
	## =================================================================================
	$where = " FROM ctninfo..Airbook_$Top_corp a,
			ctninfo..Airbook_lines_$Top_corp c,
			ctninfo..Airbook_detail_$Top_corp g,
			ctninfo..Corp_info f ";
	if ($in{ckeck_rmk} eq "Y") {##ͳ�ƻ�ƺ����¼,�����һ����  liangby@2012-8-14
		$where .=" ,#res_temp e ";
	}
	
	$where .="	WHERE a.Reservation_ID = c.Reservation_ID 
			and a.Reservation_ID=g.Reservation_ID 
			and c.Res_serial=g.Res_serial ";
	if ($in{ckeck_rmk} eq "Y") {
		$where .=" and a.Reservation_ID=e.Res_ID
			and c.Reservation_ID=e.Res_ID
			and g.Reservation_ID=e.Res_ID ";
	}
	$where .=" and a.Agent_ID = f.Corp_ID 
			and a.Sales_ID='$Corp_center' 
			and c.Sales_ID='$Corp_center'
			and g.Sales_ID='$Corp_center' 
			and f.Corp_num='$Corp_center' 
			and a.Book_status<>'C' \n";	
	if ($in{air_type} ne "" && $in{air_type} ne "ALL") {
		$where .= " and a.Air_type='$in{air_type}' ";
	}
	if ($Corp_type ne "T") {	$where .= "and a.Agent_ID='$Corp_ID' ";	}
	if ($in{Guest_name} ne "") { $where .= " and g.First_name = '$in{Guest_name}' \n";	}
	if ($in{user_book} ne "") { $where .= " and a.Book_ID = '$in{user_book}' \n";	}
	if (length($in{PNR}) == 5 || length($in{PNR}) == 6) {
		$in{PNR} =~ tr/a-z/A-Z/;
		$where .= " and a.Booking_ref = '$in{PNR}' and a.Book_time >= dateadd(month,-6,getdate()) \n"; 		
	}
	elsif ($in{Res_ID} ne "") {
		$where .= " and a.Reservation_ID='$in{Res_ID}' ";
	}
	else{
		if ($in{ckeck_rmk} eq "Y") {
			
		}else{
			$where .= "	and a.Ticket_time >= '$Depart_date'
				and a.Ticket_time < '$in{End_date}'\n";

			if ($op == 0){	$where .= "	and a.Alert_status='0' and a.Is_account = 'N' \n";		}		## �����δ��
			elsif($op==1){	$where .= "and a.Alert_status='0' and a.Is_account = 'Y' \n";	}		## ������Ѻ�
			elsif($op==2){ $where .=" and a.Alert_status ='1' and a.Is_account = 'N' \n"; }           ##��Ʊδ��  likunhua@2009-02-05
			elsif($op==3){ $where .=" and a.Alert_status ='1' and a.Is_account = 'Y' \n"; }            ##��Ʊ�Ѻ�
			elsif($op==4){ $where .=" and a.Alert_status ='2' and a.Is_account = 'N' \n"; }           ##��Ʊδ��
			elsif($op==5){ $where .=" and a.Alert_status ='2' and a.Is_account = 'Y' \n"; }            ##��Ʊ�Ѻ� 
			elsif($op==7){	$where .=" and a.Alert_status ='3' and a.Is_account = 'Y' \n";	}		##���ڵ��Ѻ�
			elsif($op==8){	$where .=" and a.Alert_status ='3' and a.Is_account = 'N' \n";	}		##���ڵ�δ��
		}
	}
	if ($in{Corp_ID} ne "") {	$where .= "and a.Corp_ID='$in{Corp_ID}' ";	}
	if ($in{office_id} ne "") {	$where .= "and a.Office_ID='$in{office_id}' ";	}
	if ($in{bank_id} ne "") {	$where .= "and a.Pay_bank='$in{bank_id}' ";	}
	if ($in{Airline_code} ne "YY") {	$where .= "and c.Airline_ID ='$in{Airline_code}' ";	}
	if ($in{B_IATA} ne "") {	$where .= "and c.Departure ='$in{B_IATA}' ";	}
	if ($in{E_IATA} ne "") {	
		if (length($in{E_IATA}) == 3) {
			$where .= "and c.Arrival ='$in{E_IATA}' ";	
		}
		else{
			$in{E_IATA} =~ s/��/','/g;	$in{E_IATA} =~ s/,/','/g;
			$where .= "and c.Arrival in ('$in{E_IATA}') ";	
		}		
	}
	if ($in{Airline} ne "") {	$where .= "and c.Flight_no ='$in{Airline}' ";	}
	if ($in{classcode} ne "") {	
		if (length($in{classcode}) == 1) {
			$where .= "and g.Seat_type ='$in{classcode}' ";	
		}
		else{
			$in{classcode} =~ s/��/','/g;	$in{classcode} =~ s/,/','/g;
			$where .= "and g.Seat_type in ('$in{classcode}') ";	
		}	
		
	}
	if ($in{bk_type} ne "") {	$where .= " and a.Book_type='$in{bk_type}' ";	}
	if ($in{tk_type} ne "") {	$where .= " and g.Is_ET='$in{tk_type}' ";	}
	if ($in{Team_name} ne "") {$in{Team_name}=~ tr/a-z/A-Z/;	$where .= " and a.Team_name='$in{Team_name}' ";	}
	if ($in{book_dept} ne "") {##��������  liangby@2016-3-27
		my ($bcorp,$dept_id)=split/,/,$in{book_dept};
		$where .=" and a.Book_ID in (select User_ID from ctninfo..User_info where Corp_ID='$bcorp' and Dept=$dept_id and Corp_num='$Corp_center' ) \n";
	}
	#if ($in{Tkt_num} ne "") {	$where .= " and g.Ticket_ID=$in{Tkt_num} \n";	}
	#print $where;
	$a_href = "air_ban_do.pl";		
	## ---------------------------------------------------------------------
	print qq?<center><script>	
	function OpenWindow(theURL,winName,features) { 
	  window.open(theURL,winName,features);
	}
	function Show_ban(resid){
		OpenWindow('$a_href\?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid,'H_'+resid,'resizable,scrollbars,width=680,height=400,left=200,top=200');
	}
	</script>
	$Header?;
	#select Res_ID,User_ID,right(convert(char(10),Op_time,102),10) + ' '+ convert(char(8),Op_time,108),
	$sql="";
	## ----------------------------------------------------------------------------
	my %office_hash = &get_office($Corp_office,"","hash","A");
	if ($in{ckeck_rmk} eq "Y") {
		$sql .= " select  Res_ID,max(Op_time) as ot into #tmp from ophis..Op_rmk where Sales_ID='$Corp_center' and Product_type='A' and Op_time >= '$Depart_date'
				and Op_time < '$in{End_date}' and Op_type='4' group by Res_ID
		 select r.Res_ID,r.User_ID,r.Op_time into #res_temp from ophis..Op_rmk r,#tmp t where r.Res_ID=t.Res_ID and r.Op_time=t.ot ";
	}
	$sql .="  select rtrim(a.Reservation_ID),right(convert(char(10),c.Air_date,102),5),c.Departure,c.Arrival,
		a.User_ID,g.Res_serial,rtrim(c.Airline_ID+c.Flight_no),g.First_name,
		g.Seat_type,g.Origin_price,g.In_price,g.Out_price, --11
		g.Insure_type,g.Insure_inprice,g.Insure_outprice,'', --15
		a.Corp_ID,f.Corp_csname,rtrim(a.Pay_bank),a.Book_status, --19
		a.APay_method,rtrim(a.Card_no),f.Corp_num,a.Abook_method, --23
		g.Insure_num,g.In_yq,a.Recv_total, --26
		a.Agt_total+a.Insure_out+a.Other_fee+isnull(a.Service_fee,0)-a.Recv_total,rtrim(a.Booking_ref),g.Tax_fee, --29
		convert(integer,g.Recv_price),g.Ticket_ID,g.In_discount,g.Agt_discount, --33
		0,g.Is_ET,g.Air_code,a.Other_fee,a.Book_ID,a.If_out,g.Return_price,g.SCNY_price,isnull(g.Service_fee,0),g.In_tax,a.Office_ID,a.Air_type,right(convert(char(10),a.Ticket_time,102),10),g.YQ_fee --47 \n ";

	#ʵ�ռ�=���� Out_price+˰ Tax_fee+���������� Service_fee
	#ʵ����=ʵ���� In_price+����˰ In_tax
	#��˾ë��=ʵ�ռ�-ʵ���� $row[11]+$row[29]+$row[42]-$row[10]-$row[43] lyq@2016-03-17
	if ($in{ckeck_rmk} eq "Y") {##�����ˣ�����ʱ��,Ϊ��Ӱ������ͳ�ƣ�����һֱ����� liangby@2012-8-14
		$sql .=",e.User_ID,convert(char(10),e.Op_time,102)+' '+convert(char(8),e.Op_time,108) ";
	}
	$sql .= $where;
	if ($in{Order_type}==1) {
		$sql .= "\n order by a.Corp_ID,g.Ticket_ID,g.Res_serial "; 
	}
	elsif ($in{Order_type}==2) {
		$sql .= "\n order by a.Ticket_time "; 
	}
	else{
	    $sql .= "\n order by g.Ticket_ID,g.Res_serial "; 
	}
	
	if ($in{ckeck_rmk} eq "Y") {
		$sql .=" drop table #tmp ";
		$sql .= "drop table #res_temp";
	}
	## ---------------------------------------------------------------------
	my $temp_id = $tmp_serial = "";
	my $Air_date = "";
	$ii = -1;
	$Find_res = 0;
	$n_bk=0;
	@price=(0,0,0,0);
	#print "<PRE>$sql";
	$dnum=1;
	$maxdnum=1;
	my %disp_res=(); ##����ë������Ķ���
	if($in{Profit_b} !~ /\d+/){ $in{Profit_b} =-99999999; }
	if($in{Profit_e} !~ /\d+/){ $in{Profit_e} =99999999; }
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				if($row[43] eq "" || $row[43]==0){ $row[43]=$row[29]; }
				if ($in{Profit_b} != -99999999 || $in{Profit_e} != 99999999) { ##�ҳ�����ë������Ķ��ţ�ֻҪ��һ�г�������ʾ�������� lyq@2016-03-17
					my $corp_profit=$row[11]+$row[29]+$row[42]-$row[10]-$row[43]; ##��˾ë��
					if($corp_profit>=$in{Profit_b} && $corp_profit<$in{Profit_e}){
						$disp_res{"$row[0]"}="Y";
					}
				}
				push(@list,[@row]);
			}
		}
	}
	foreach my $temp (@list) {
		@row = @{$temp};
		if ($in{Profit_b} != -99999999 || $in{Profit_e} != 99999999) { ##���˲�����ë������Ķ���
			if($disp_res{"$row[0]"} ne "Y"){ next; }
		}
		my $Pay_method="<font color=blue>�ָ�";		
		my $card_no=$row[21];	if ($card_no eq "" ) {	$card_no =$row[4];	}	my $userid=$row[4];
		my $s_city = $row[2];	my $e_city = $row[3];	my $tk_id=$row[31];		my $in_dis=$row[32];
		my $agt_dis=$row[33];	my $r_price=$row[30];	my $insure=0;
		my $a_code=$row[36];	my $If_out=$row[39];	my $seat=$row[8];
		my $et_type=$tkt_type{$row[35]};
		if ($tk_id eq "0") {	$tk_id="0000000000";	}
		if ($a_code eq "") {	$a_code="000";			}
		if ($in{Tkt_num} ne "" && "$a_code-$tk_id"!~/$in{Tkt_num}/ && "$a_code$tk_id"!~/$in{Tkt_num}/) {#Ʊ��ģ����ѯ
			next;
		}
		## �ͻ����ʽ	 Abook_method
		my $j_pay=$row[23];		my $in_num=$row[24];	my $in_yq=$row[25];						
		if($row[23] eq "C" ){	$Pay_method="<font color=blue>�ָ�";	}else{	$Pay_method="<font color=red>����";	} 
		my $bk_status = "����";	$bk_status = &cv_airstatus($row[19],"S",$t_left);
		my $other_fee=0;
		my $book_id=$row[38];
		my $corpid=$row[16];
		my $air_type=$row[45];
		$use_intax="Y";
		if ($G_ZONE_ID ne "3" && $Air_parm !~/s/ && (($Air_parm !~/q/ && $air_type eq "Y" ) || ($Air_parm !~/o/ && $air_type ne "Y")) ) {
			$use_intax="N";   ##�ɰ�鿴����ҳ�治ʹ�ý���˰   liangby@2018-1-15
		}
		my $Ticket_time=$row[46];
		
		my $guest_name = &cut_str($row[7],8);

		if ($temp_id ne $row[0]){	## �¶���
			$other_fee=$row[37];
			$office_id=$row[44];$office_name=$office_hash{$office_id};
			#print "<tr><td height=20><b>$bk_total</td></tr>";		$bk_total = 0;
			$Find_res ++;
			$n_bk ++;
			$dnum=1;
			$tmp_serial = $row[5];		
			my $pnr=$row[28];	
			if ($pnr eq "") {	$pnr="-----";	}
			else{
				$pnr = qq!<a href="javascript:Show_pnr('$row[0]','$pnr');" title='��ȡ����'>$pnr</a>!;
			}
			print qq!<tr align=center>!;
			if ($Find_res == 1) {							
				if (($type eq "H" && $row[19] ne "H") || $type eq "A") {
					$jump_w = qq!Show_ban('$row[0]')!;
				}
			}
			$Air_date=$row[1];	
			if ($op==1||$op==3||$op==5||$op==7) {
			   print qq!<td><img src='/admin/index/images/checka.gif'></td>!;
			}else{
			   print qq!<td align=center><input type=Checkbox name=cb_$n_bk id="cb_$n_bk" value=$row[0]></td>!;
			}
			my $show_Ticket_time=substr($Ticket_time,5);
			print qq!
			<td align=left height=20><a href="javascript:Show_ban('$row[0]');" title='���ʺ���'>$row[17]</a></td>
			<td>$CORP_NAME{$corpid}[0]</td>
			<td>$USER_NAME{$book_id}[1]</td>
			<td>$USER_NAME{$book_id}[3]&nbsp;</td>
			<td>$pnr</a></td>
			<td><a href="javascript:Show_his('$row[0]');" title='������¼'>$bk_status</td>
			<td align=left>$office_id&nbsp;</td>
			<td>$et_type&nbsp;</td>
			<td align=left>$pay_name{$row[18]}&nbsp;</td>
			<td><a href="javascript:Show_book('$row[0]');" title='$Ticket_time'>$show_Ticket_time</td>!;
			$ticket_id_tag = "$a_code-$tk_id";
			print "<td align=center>$a_code-$tk_id</td>";
			## ����
			
			if(	$row[12] eq "F" && $row[14] == 0){
				print "<td align=left>$guest_name<font color=red>-$in_num</td>";
			}				
			else{
				if ($in_num > 0) {
					print "<td align=left>$guest_name<font color=blue>+$in_num</td>";	
					#$recv = $recv + $in_num * $row[14];
					$insure = $row[14] * $in_num ;
					
				}else{
					print "<td align=left>$guest_name</td>";
				}
			}
			print qq!<td><a href="javascript:Show_book('$row[0]');" title='��������'>$Air_date</td>
			<td>$s_city</td>
			<td>$e_city</td>					
			<td>$row[6]</td>
			<td>$seat</td>
			!;
			$temp_id = $row[0];	
		}
		else{
			
			print "<tr align=center>";
			## ��Ʊ��
			$Air_date=$row[1];
			$old_col = 11;
			if ($ticket_id_tag ne "$a_code-$tk_id") {
				print qq!<td height=20 colspan=$old_col>��</td>
						<td>$a_code-$tk_id</td>
						<td>$guest_name</td>!;
				$ticket_id_tag = "$a_code-$tk_id";
			}else{
				print "<td height=20 colspan=13> </td>";
			}
			print "<td>$Air_date</td>
					<td>$s_city</td>
					<td>$e_city</td>
					<td>$row[6]</td>
					<td>$seat</td>
					";	
		}

		if ($in{datadown} eq "Y") {
			$iCol=0;
			$bk_status =~ s/<.*?>//g;
			$worksheet->write_string($iRow,$iCol,$row[17],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$CORP_NAME{$corpid}[0],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$USER_NAME{$book_id}[1],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$USER_NAME{$book_id}[3],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[28],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$bk_status,$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$office_id,$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$et_type,$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$Ticket_time,$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[7],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,"$a_code-$tk_id",$format1);	$iCol=$iCol+1;	
			$worksheet->write_string($iRow,$iCol,$Air_date,$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$s_city,$format1);	$iCol=$iCol+1;	
			$worksheet->write_string($iRow,$iCol,$e_city,$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[6],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$seat,$format1);	$iCol=$iCol+1;
		}

		## ���ʽ	
		my $a_price=$row[9];	my $i_price=$row[10];		my $o_price=$row[11];
		my $return_price=$row[40];  ##��Ʊ��
		my $scny_price =$row[41];    ##���� SCNY
		my $in_tax=$row[43];		my $service_fee=$row[42];
		my $tax=$row[29];  my $yq_fee=$row[47];
		if ($in_tax==0 || $in_tax eq "") {##��ʷ����Ϊ��   liangby@2017-10-17
			$in_tax=$tax;
		}
		if ($in_yq==0 || $in_yq eq "") {
			$in_yq=$yq_fee;
		}
		my $comm = $o_price-$a_price;
		my $profit=$o_price-$i_price;
		if ($air_type eq "Y") {
			$profit=$row[11]+$row[29]+$row[42]-$row[10]-$row[43]; ##����Ʊ
		}else{
			if ($use_intax ne "N") {
				$profit=$profit+($tax+$yq_fee-$in_tax-$in_yq); ##����˰����  liangby@2017-11-13
			}
		}
		
		$comm = sprintf("%.2f",$comm);	## ��Ӷ	
		$profit = sprintf("%.2f",$profit);
		my $i_total=$i_price+$in_tax+$in_yq;		$i_total=sprintf("%.2f",$i_total);	##����С��
		$r_price =~ s/\s*\.00//;			$a_price =~ s/\s*\.00//;	$i_price =~ s/\s*\.00//;
		$o_price =~ s/\s*\.00//;			$comm =~ s/\s*\.00//;
		
						
		$COrigin_price = $COrigin_price + $a_price;
		$CIn_price = $CIn_price + $i_price;
		$COut_price = $COut_price +$o_price ;
		$CTax = $CTax + $in_tax ;
		$CTax_G = $CTax_G + $tax ;
		$CTotal = $CTotal + $recv;
		$CYQ = $CYQ + $in_yq;	
		$CYQ_G = $CYQ_G + $yq_fee;	
		$Ccomm = $Ccomm + $comm;	
		$CProfit=$CProfit+$profit;
		$CI_total = $CI_total + $i_total;
		$CService_fee=$CService_fee+$service_fee;
		$CReturn_price = $CReturn_price + $return_price;
		$CSCNY_price = $CSCNY_price +$scny_price;
		$CTk_num++;
		$agency_fee = $scny_price-$i_price;
		$Cagency_fee +=$agency_fee; 
		## Ʊ��
		if ($op == 0 or $op == 1 or $op == 7 or $op == 8) {
			print "<td align=center>$in_dis</td>";
		}
		else{
			print "<td align=center>$return_price</td>";
		}					
		print "<td align=center>$o_price</td>";
		if ($in{air_type} eq "Y") {
			print "<td align=center>$scny_price</td>
					<td align=center>$in_tax</td>
					<td align=center>$tax</td>";
		}
		else{	print "<td align=center>$in_tax</td>
			<td align=center>$in_yq</td>
			<td align=center>$tax</td>
			<td align=center>$yq_fee</td>";	
		}
		print "<td align=center>$i_price</td>
		<td align=center>$agency_fee</td>
		<td align=center>$profit</td>";
		print "<td align=center>$service_fee</td>";
		print "<td align=center>$i_total<input type=hidden name='in_total_$n_bk\_$dnum' id='in_total_$n_bk\_$dnum' value='$i_total'></td>";
		if ($in{ckeck_rmk} eq "Y") {
			my $check_man=$row[42];
			my $check_time=$row[43];
			print "<td>$USER_NAME{$check_man}[1] $check_man</td><td>$check_time</td>";
		}
		print "</tr>\n";

		if ($in{datadown} eq "Y") {
			if ($op == 0 or $op == 1 or $op == 7 or $op == 8) {
				$worksheet->write_number($iRow,$iCol,$in_dis,$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$agt_dis,$format1);	$iCol=$iCol+1;
			}
			else{
				$worksheet->write_number($iRow,$iCol,$return_price,$format1);	$iCol=$iCol+1;
			}
			if ($in{air_type} eq "Y") {
				$worksheet->write_number($iRow,$iCol,$scny_price,$format1);	$iCol=$iCol+1;
			}

			$worksheet->write_number($iRow,$iCol,$i_price,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$a_price,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$o_price,$format1);	$iCol=$iCol+1;
			if ($in{air_type} eq "Y") {
				$worksheet->write_number($iRow,$iCol,$in_tax,$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$tax,$format1);	$iCol=$iCol+1;
			}else{
				$worksheet->write_number($iRow,$iCol,$in_tax,$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$in_yq,$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$tax,$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$yq_fee,$format1);	$iCol=$iCol+1;
			}
			$worksheet->write_number($iRow,$iCol,$comm,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$agency_fee,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$profit,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$service_fee,$format1);	$iCol=$iCol+1;
			$worksheet->write_number($iRow,$iCol,$i_total,$format1);	$iCol=$iCol+1;
			if ($in{ckeck_rmk} eq "Y") {
				my $check_man=$row[42];
				my $check_time=$row[43];
				$worksheet->write_string($iRow,$iCol,"$USER_NAME{$check_man}[1] $check_man",$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$check_time,$format1);	$iCol=$iCol+1;
			}
			$iRow=$iRow+1;
		}
		$dnum++;
		if ($maxdnum<$dnum) {$maxdnum=$dnum;}
	}

	#print "<tr><td height=20><b>$bk_total</td></tr>";
	if ($Find_res > 0) {	&sum_ban('Y');	}	
	else{
		print "<tr><td height=20 colspan=28><font color=red>ϵͳ��ʾ��û�з������������ݡ�</td></tr>";
	}
	if ($Find_res == 1 && $jump_w ne "" && $op < 3) {
		print qq!<script>$jump_w</script>!;
	}
	print "</table>";
}

## ��������	add by zhengfang 2007-07-06
sub air_account_recv {
	##��ȡ��ƿ�Ŀ����Ϣ��ϣ��  liangby@2015-6-11
	my %kemu_hash = &get_kemu($Corp_center,"","hash2","","","","assist","N");
	##���˷�ʽ
	%pre_kemu_hash=&get_dict($Corp_center,4,"","hash2");
	my @pay_method=();
	$in{pay_method_num}=sprintf("%.0f",$in{pay_method_num});
	if ($in{pay_method_num}<1) {$in{pay_method_num}=1;}
	for (my $p=0;$p<$in{pay_method_num} ;$p++) {##���ָ����Ŀ	fanzy@2015-04-17
		my $pp=($p==0)?"":"_$p";
		my %pay_method_info=();
		$pay_method_info{pay_method}=$in{"pay_method".$pp};			#�����Ŀ
		$pay_method_info{Pay_type2}=$in{"Pay_type2".$pp};		#������Ŀ
		$pay_method_info{ReferNo}=$in{"ReferNo".$pp};			#���ײο���
		$pay_method_info{BankName}=$in{"BankName".$pp};			#������
		$pay_method_info{ReOp_date}=$in{"ReOp_date".$pp};		#��������
		$pay_method_info{BankCardNo}=$in{"BankCardNo".$pp};		#���ź���λ
		$pay_method_info{Pay_Recv_total}=$in{"Pay_Recv_total".$pp};		#�����Ŀʵ��
		$pay_method_info{Pay_Recv_total_copy}=$in{"Pay_Recv_total".$pp};		#�����Ŀʵ�ձ��ݣ�������ۿ��õ�����ֹ��ȥת��������Ľ��   liangby@2016-12-19
		$pay_method_info{pingzheng}=$in{"pingzheng".$pp};		##ƾ֤��
		push(@pay_method,\%pay_method_info);
	}
	#����ȯ
	$in{ccp_total}=sprintf("%.2f",$in{ccp_total});
	if ($in{ccp_total}>0 && $in{t_num}==1 && $in{cb_0} ne "") {
		$ccp_resid=$in{cb_0};
		$sql_t = "select a.User_ID,a.Mobile_no,b.Userbp
			from ctninfo..User_info a,
				ctninfo..Airbook_$Top_corp b
			where a.User_ID=b.User_ID
			and a.Corp_num='$Corp_center'
			and b.Sales_ID='$Corp_center'
			and b.Reservation_ID='$ccp_resid'
			and a.User_type='C' ";
		$db->ct_execute($sql_t);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					($ccp_userid,$ccp_mobile,$ccp_userbp)=@row;
					$ccp_mobile=($ccp_mobile eq "")?$ccp_userbp:$ccp_mobile;
				}
			}
		}
		my @CCP_no_arr=();
		for (my $j=0;$j<$in{num};$j++) {
			if ($ccp_resid ne $in{"resia_$j"}) {
				next;
			}
			my $r_price="recv_account_$j";	$in{$r_price}=sprintf("%.2f",$in{$r_price});$in{$r_price}=~ s/\s*\.00//;
			my $ccpid="ccpid_$j";
			if ($in{$r_price}>0 && $in{$ccpid} ne "") {
				push(@CCP_no_arr,$in{$ccpid});
			}
		}
		my $CCP_no_str=join("','",@CCP_no_arr);
		if ($CCP_no_str ne "" && $ccp_userid ne "") {
			my %CCP_Amount=();
			my $sql_ccp="select CCP_no,Amount from ctninfo..CCP_voucher where Sales_ID='$Corp_center' and User_ID='$ccp_userid' and Status='Y' and CCP_no in('$CCP_no_str')\n";
			$db->ct_execute($sql_ccp);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$CCP_Amount{$row[0]}=$row[1];
					}
				}
			}
			my @ccp_method=();my $ccp_total=0;
			for (my $j=0;$j<$in{num};$j++) {
				if ($ccp_resid ne $in{"resia_$j"}) {
					next;
				}
				my $r_price="recv_account_$j";	$in{$r_price}=sprintf("%.2f",$in{$r_price});$in{$r_price}=~ s/\s*\.00//;
				my $ccpid="ccpid_$j";
				my $ccp_amount=sprintf("%.2f",$CCP_Amount{$in{$ccpid}});
				if ($in{$r_price}>0 && $in{$ccpid} ne "") {
					if ($ccp_amount>$in{$r_price}) {
						print MessageBox("������ʾ","�Բ��𣬴���ȯ���ܴ���ʵ�ս�");
						exit;
					}
					if (sprintf("%.0f",$in{sxk_credit})>0) {
						print MessageBox("������ʾ","�Բ��𣬴���ȯ���ֵ�������һ��ʹ�ã�");
						exit;
					}
					my %pay_method_info=();
					$pay_method_info{pay_method}="4003.01.03";				#�����Ŀ
					$pay_method_info{pingzheng}=$in{$ccpid};				##ƾ֤��
					$pay_method_info{Pay_Recv_total}=sprintf("%.2f",$CCP_Amount{$in{$ccpid}});		#�����Ŀʵ��
					$pay_method_info{pingzheng_other}=$j;		#Ҫ�ֿ۵��ÿ�id
					$ccp_total+=sprintf("%.2f",$CCP_Amount{$in{$ccpid}});
					push(@ccp_method,\%pay_method_info);
				}
			}
			if (sprintf("%.2f",$ccp_total)!=$in{ccp_total}) {
				print MessageBox("������ʾ","�Բ��𣬴���ȯ�������");
				exit;
			}
			@pay_method=(@ccp_method,@pay_method);
			$in{pay_method_num}=scalar(@pay_method);
		}
	}
	##�ж��ظ�ƾ֤��,Ϊ���������ж���������ͬһ����ͬһ��Ŀƾ֤�ű���Ψһ   liangby@2015-6-11
	my @tradeno_check=();
	my $tuik_num=0;
	my $tuik_num2=0;
	for (my $p=0;$p<$in{pay_method_num} ;$p++) {##���ָ����Ŀ	fanzy@2015-04-17
		if ($pay_method[$p]{pingzheng} ne "") {
			push(@tradeno_check,$pay_method[$p]{pay_method}."&,".$pay_method[$p]{Pay_type2}."&,".$pay_method[$p]{pingzheng});
		}
		my $Pay_type=$pay_method[$p]{pay_method};			#�����Ŀ
		my $pingzheng=$pay_method[$p]{pingzheng};				#ƾ֤��
		my $Pay_t_recv=$pay_method[$p]{Pay_Recv_total};
		if ($Pay_t_recv<0 && $Pay_type eq "1003.02.25.01" ) {
			$tuik_num++;
		}
		if ($Pay_t_recv>0 && $Pay_type eq "1003.02.25.01" ) {
			$tuik_num2++;
		}
		
	}
	if ($tuik_num>1) {
		print MessageBox("������ʾ","��Ʊ���������ֻ��ѡһ��'��Ʊ���������'��Ŀ"); 
		exit;
	}
	if ($tuik_num==1) {##ֻ֧��һ����Ʊ������  liangby@2018-1-12
		$sl_num=0;
		for ($i=0;$i<$in{t_num};$i++) {
			my	$cb="cb_$i";	my $res_id=$in{$cb};
			if ($res_id ne "") {	## ѡ�еĶ���
			   $sl_num++;
			 }

		}
		if ($sl_num>1) {
			print MessageBox("������ʾ","��Ʊ���������ֻ��ѡһ����Ʊ�����в���"); 
			exit;
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
	if ($in{Comment} eq " " || $in{Comment} eq "��") {$in{Comment}="";}
	$in{Comment} =~ s/'/��/g;	$in{Comment} =~ s/"/��/g;
	if (length($in{Comment}) > 80 ) {
		print MessageBox("������ʾ","�Բ��𣬱�ע�������������������� 40 �����֣�");
		exit;
	}
	$in{Recv_total}=sprintf("%.2f",$in{Recv_total});
	$in{sxk_credit}=sprintf("%.2f",$in{sxk_credit});
	my $sxk_offset=$in{sxk_credit};
	my $Pay_Recv_totals=0;
	if ($sxk_offset>0 && $center_airparm=~/g/) {
		for (my $p=($in{pay_method_num}-1);$p>=0 ;$p--) {
			my $pp=($p==0)?"":"_$p";
			$pay_method[$p]{Pay_Recv_total}=sprintf("%.2f",$pay_method[$p]{Pay_Recv_total});
			$Pay_Recv_totals+=$pay_method[$p]{Pay_Recv_total};
			my $sxk_shortfall=($sxk_offset>$pay_method[$p]{Pay_Recv_total})?$pay_method[$p]{Pay_Recv_total}:$sxk_offset;
			if ($in{pay_method_num}==1 && $pay_method[$p]{Pay_Recv_total}==0) {
				$sxk_shortfall=$sxk_offset;
			}
			$pay_method[$p]{Pay_Recv_total}=sprintf("%.2f",$pay_method[$p]{Pay_Recv_total}-$sxk_shortfall);
			$sxk_offset=sprintf("%.2f",$sxk_offset-$sxk_shortfall);
		}
		if ($sxk_offset!=0 || (sprintf("%.2f",$in{Recv_total}+$in{sxk_credit})!=$Pay_Recv_totals)) {
			print MessageBox("������ʾ","�Բ��������������");
			exit;
		}
	}
	my $Operate_date="convert(char(10),getdate(),102)";
	my $Operate_msg="";
	if (($Function_ACL{CWSY}&(1<<0))!=0 && $in{Operate_date} ne "" && $in{Operate_date} ne $today) {
		$Operate_date="'$in{Operate_date}'";
		$Operate_msg=",ָ����������:$in{Operate_date}";
		$sql_pay_day="delete from ctninfo..Airbook_pay_day where Operate_date ='$in{Operate_date}' and Sales_ID='$Corp_center' \n";
	}
	##-----------------------------
	my @bkcorp_arr=();
	my %resid_corp=();
	my %resid_amount=();
	($paykemu_tp,$pay_bank_tp,$payment_rmk_tp,$trade_no_tp)=();   ##�������ж���   liangby@2015-12-9
	my @sql_array=(); ##sql����ִ��    liangby@2017-2-2
	for ($i=0;$i<$in{t_num};$i++) {
		my	$cb="cb_$i";	my $res_id=$in{$cb};
		#print MessageBox("������ʾ","����$res_id,$in{inc_insure_num},$Corp_center,$in{User_ID},$in{inc_insure_type},$in{pay_method},$in{Serial_no}"); exit;
		if ($res_id ne "") {	## ѡ�еĶ���
			my $tkt_diff;
			$sql = "select b.User_ID,b.Book_status,b.Agt_total+b.Insure_out+b.Other_fee+isnull(b.Service_fee,0)-b.Recv_total,
					b.Is_reward,b.Corp_ID,b.Ticket_time,b.If_out,b.Air_type,b.Insure_recv,b.Cost_type,Alert_status,
					b.Pay_method,b.Agt_total+b.Insure_out+b.Other_fee+isnull(b.Service_fee,0),b.AAboook_method,b.Userbp,b.Delivery_method,b.Send_date,datediff(day,b.Ticket_time,getdate()),
					b.Old_resid,b.Recv_total,b.Abook_method,b.Tag_str,b.Other_fee
				from ctninfo..Airbook_$Top_corp b
				where b.Sales_ID='$Corp_center' and b.Reservation_ID='$res_id' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						($user_id,$old_status,$left_total,$is_reward,$bk_corp,$old_ticket_time,$if_out,$Air_type,$sale_code,
							$Cost_type,$is_refund,$old_pay,$old_agt_total,$comm_method,$Mobile,$old_delivery_method,$cust_pay_date,$tkt_diff,
							$old_resid,$old_recv_total,$pre_pay_by,$old_Tag_str,$old_otherfee)=@row;
					}
				}
			}
			push(@bkcorp_arr,$bk_corp);
			$resid_corp{$res_id}=$bk_corp;
			my $c_sql;	## ���ÿͻ���������	dabin@2012-12-26
			if ($cust_pay_date eq "") {
				if ($old_ticket_time eq "") {
					$c_sql = ",Send_date=getdate()";
				}
				else{
					$c_sql = ",Send_date=Ticket_time";
				}
			}
			
			if ($old_status ne "S" && $old_status ne "H" && $old_status ne "P") {	
				&write_log_account("��Ʊ��������:$res_id($old_status)���ܶ�δ��Ʊ����$res_id ����������������");
				print MessageBox("������ʾ","�Բ��𣬲��ܶ�δ��Ʊ����$res_id ������������������"); 
				exit;	
			}
			if ($left_total == 0 && $old_agt_total !=0 ) {
				print MessageBox("������ʾ","�Բ��𣬶���$res_id�Ѿ����й�����������"); 
				&write_log_account("��Ʊ��������:$res_id($left_total,$old_agt_total)�Ѿ����й���������");
				exit;	
			}
			my ($old_res_recv,$old_res_pricetotal)=();
			if ($old_resid ne "" && ($is_refund eq "1" || $is_refund eq "2")) {
				$sql_tt=" select Recv_total,Agt_total+Insure_out+Other_fee+isnull(Service_fee,0) from ctninfo..Airbook_$Top_corp
					where Sales_ID='$Corp_center'
						and Reservation_ID='$old_resid' ";
				$db->ct_execute($sql_tt);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							$old_res_recv =$row[0];
							$old_res_pricetotal=$row[1];
						}
					}
				}
			}
			if (($is_refund eq "1" || $is_refund eq "2")
				 && ($old_pay eq "P" || $old_pay eq "6" || $old_pay eq "AF" || $old_pay eq "K" || $old_pay eq "8" || $old_pay eq "AP")) {
				my $pay_exists;
				$sql=" select * from ctninfo..Airbook_pay_yd where Reservation_ID='$old_resid' ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							$pay_exists="Y";
						}
					}
				}
				if ($pay_exists eq "Y") {
					&write_log_account("��Ʊ��������:$res_id:��Ʊ����$res_idԭĸ��ʹ������֧��,��������������,ֻ�ɵ�������");
					print MessageBox("������ʾ","�Բ�����Ʊ����$res_idԭĸ��ʹ������֧��,��������������,ֻ�ɵ���������"); 
					exit;
				}
			}
			## ����Ƿ��ǻ�ԱԤ��
			$bk_type = &get_mcard_type($user_id);

			my $is_netpay="N";
			if ($old_pay ne "N" && $old_pay ne "0") {##����֧�����Ĳ��ٿ۶��        liangby@2009-3-25
				$sql_tt="select Is_netpay from ctninfo..d_paymethod where Pay_method='$old_pay' and Corp_ID='SKYECH' " ;
				$db->ct_execute($sql_tt);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if ($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							$is_netpay=$row[0];
						}
					}
				}
			}
			my $pay_rescount=0;
			for (my $p=0;$p<$in{pay_method_num} ;$p++) {##����֧����ʽ	fanzy@2015-04-14
				$pay_method[$p]{Pay_Recv_total}=sprintf("%.2f",$pay_method[$p]{Pay_Recv_total});$pay_method[$p]{Pay_Recv_total}=~ s/\s*\.00//;
				
				my $p_sh_recv=sprintf("%.2f",$pay_method[$p]{Pay_Recv_total_copy});  ##�������õ�   liangby@2015-7-8
				my $the_last=$in{pay_method_num}-$p;
				if ($the_last!=1 && $pay_method[$p]{Pay_Recv_total}==0) {
					next;
				}
				my $pay_type_t=$pay_method[$p]{pay_method};
				if ($is_netpay eq "Y" && $is_refund eq "0") {##����֧���Ĳ��޸Ķ�����֧�����          liangby@2009-4-2
					$pay_type_t =$old_pay;
				}
				## ������
				#$sql_upt = "begin transaction sql_insert \n
				# declare \@op_type varchar(1) ";
				$sql_upt = "declare \@op_type varchar(1) \n";
				$sql_upt.=$sql_pay_day;
				my $tcomm_tmp_id=0;
				my $t_recv_total=0;   ##�տ���,���ֵֿ��õ�  liangby@2012-10-23
				if (($is_refund eq "1" || $is_refund eq "2") && $bk_corp ne $Corp_center && $p_sh_recv<0 && $pay_method[$p]{pay_method} eq "1003.02.25.01" ) {
			
					if ($old_res_recv ne "" && $old_res_pricetotal>0 && $old_res_recv==0) {
						print MessageBox("������ʾ","����Ʊ��ԭ��Ʊ����δ�����������Խ���Ʊ�����������"); 
						exit;
					}
					
					#$c_trade_no=$pay_method[$p]{pingzheng};
					##��Ʊ���������  liangby@2018-1-8
					my $rt_result=&use_credit_payment($bk_corp,$pay_method[$p]{pay_method},$pay_method[$p]{Pay_type2},$c_trade_no,$p_sh_recv,$res_id,"","",$p_sh_recv,$c_rmk,"2");
					if ($rt_result=~/<error>/) {
						$rt_result=~ s/<error>//g;
						$rt_result=~ s/<\/error>//g;
						print MessageBox("������ʾ","�Բ���$rt_result"); 
						exit;
					}else{
						$tpsck_tradeno="'$res_id'+'_'+convert(varchar,\@c_sno)" ;
						$tpsck_tradeno2="'ƾ֤��:$res_id'+'_'+convert(varchar,\@c_sno)" ;
						$sql_upt .=$rt_result;
						if ($rt_result=~/Corp_credit_payment/) {
							$payment_str="[�˵�������]";
							$Pay_status="TS";
						}
					}
					$sxk_credit="";
				}
				for ($j=0;$j<$in{num};$j++) {
					my	$cb_tmp="resia_$j";		my $res_id_per=$in{$cb_tmp};
					if ($res_id eq $res_id_per) {
						if ($pay_method[$p]{pingzheng_other} ne "" && $pay_method[$p]{pingzheng_other} ne $j) {
							next;
						}
						my $res_tmp="res_tmp_$j";my $res_tmp_id=$in{$res_tmp};
						my $last_tmp="last_tmp_$j";my $last_tmp_id=$in{$last_tmp};
						my $ticket_tmp="ticket_tmp_$j";my $ticket_tmp_id=$in{$ticket_tmp};
						my $tcomm_tmp="tcomm_tmp_$j";
						$tcomm_tmp_id =$tcomm_tmp_id+$in{$tcomm_tmp};
						my $airdate_tmp="airdate_tmp_$j";$airdate_tmp_id=$in{$airdate_tmp};
						my $r_price="recv_account_$j";	$in{$r_price}=sprintf("%.2f",$in{$r_price});$in{$r_price}=~ s/\s*\.00//;
						my $new_recv_price="new_recv_price_$j";
						
						if ($in{$r_price} != 0) {
							my $old_account_period;
							my $must_recv;  ##Ӧ��   liangby@2015-4-30
							$sql_tt=" select  Recv_price,Origin_price,Out_price,Tax_fee+YQ_fee+Insure_outprice*Insure_num+Other_fee+isnull(Service_fee,0),Account_period from ctninfo..Airbook_detail_$Top_corp 
							   where Reservation_ID='$res_id' and Res_serial=$res_tmp_id 
								and Last_name='$last_tmp_id'";
							$db->ct_execute($sql_tt);
							while($db->ct_results($restype) == CS_SUCCEED) {
								if ($restype==CS_ROW_RESULT)	{
									while(@row = $db->ct_fetch)	{
										$old_recv_price=$row[0];
										$old_account_period=$row[4];
										if ($comm_method eq "T") {
											$must_recv=$row[2]+$row[3]-$row[0];
										}else{
											$must_recv=$row[1]+$row[3]-$row[0];
										}
									}
								}
							}
							if (!exists($must_recv_dt{"$res_id,$res_tmp_id,$last_tmp_id"})) {
								
								$must_recv_dt{"$res_id,$res_tmp_id,$last_tmp_id"}=$must_recv;
							}else{##���ۻ�ʣ���  liangby@2017-2-14
								$must_recv=$must_recv_dt{"$res_id,$res_tmp_id,$last_tmp_id"};
							}
							$must_recv=sprintf("%.2f",$must_recv);

							if ($in{$new_recv_price} != $old_recv_price ) {
								&write_log_account("��Ʊ��������:$res_id($in{$new_recv_price},$old_recv_price)���ս����˱仯����ֹ����");
								print MessageBox("������ʾ","�Բ��𣬶���$res_id���ս����˱仯����ֹ������"); 
								exit;
							}
							my $once_price=$in{$r_price};
							while(($the_last==1 || $pay_method[$p]{Pay_Recv_total}!=0) && $in{$r_price}!=0){
								my $balance=sprintf("%.2f",($pay_method[$p]{Pay_Recv_total}-$once_price));$balance=~ s/\s*\.00//;
								if ($the_last!=1 && (($in{$r_price}>0 && $pay_method[$p]{Pay_Recv_total}>0 && $balance<0) || ($in{$r_price}<0 && $pay_method[$p]{Pay_Recv_total}<0 && $balance>0))) {
									$once_price=$pay_method[$p]{Pay_Recv_total};
								}else{
									$once_price=$in{$r_price};
								}
								$resid_amount{$res_id}+=$once_price;
								$total_use = $total_use+$once_price;
								#$in{$new_recv_price}=sprintf("%.2f",($in{$new_recv_price}+$once_price));
								#$in{$new_recv_price}=~ s/\s*\.00//;
								$pay_method[$p]{Pay_Recv_total}=sprintf("%.2f",($pay_method[$p]{Pay_Recv_total}-$once_price));$pay_method[$p]{Pay_Recv_total}=~ s/\s*\.00//;
								$in{$r_price}=sprintf("%.2f",($in{$r_price}-$once_price));$in{$r_price}=~ s/\s*\.00//;
								##�������Ƿ��   liangby@2010-12-23
								$sql_upt .=" delete from ctninfo..Airbook_pay_$Top_corp 
									  where Reservation_ID='$res_id' and Res_serial=$res_tmp_id
										 and Last_name='$last_tmp_id' and Op_type in ('G','S') and Operate_date=$Operate_date and Pay_object <>'0' \n
									update ctninfo..Airbook_pay_$Top_corp set Left_total=0
										 where Reservation_ID='$res_id' and Res_serial=$res_tmp_id 
										 and Last_name='$last_tmp_id'  and Op_type in ('H','G','S') and Operate_date=$Operate_date and Pay_object <>'0' \n";
							
								$sql_upt .=" select \@op_type='H' \n";
								if ($comm_method eq "T" && (($is_refund ne "1" && $is_refund ne "2" && $left_total <0 && $once_price <0) || (($is_refund eq "1" || $is_refund eq "2") && $left_total >0 && $once_price >0)) ) {##��������д�󷵼�¼ liangby @2010-12-26
									$sql_upt .=" if not exists(select * from ctninfo..Airbook_pay_$Top_corp where Reservation_ID='$res_id' and Res_serial=$res_tmp_id and Last_name='$last_tmp_id' and Op_type='E' )
									   begin
										   if $once_price=(select Origin_price-Out_price from ctninfo..Airbook_detail_$Top_corp where Reservation_ID='$res_id' and Res_serial=$res_tmp_id and Last_name='$last_tmp_id' )
										   begin
											   select \@op_type='E'
											end
									   end \n ";
									
								}
								$sql_upt .= " update ctninfo..Airbook_detail_$Top_corp set Recv_price=Recv_price+$once_price where Reservation_ID='$res_id' and Res_serial=$res_tmp_id and Last_name='$last_tmp_id' \n";
								if ($old_account_period ne "") {	##�����˵������� linjw@2016/12/16 ���˵���Ʊ������Ʊ��ͳ�ƣ�
									$sql_upt .= " update ctninfo..Account_info set Clear_amount=Clear_amount+$once_price where Corp_ID='$bk_corp' and Account_period=$old_account_period and Serial_id=1 and Sales_ID='$Corp_center' \n";
								}
								if ($pay_method[$p]{pay_method} eq "1003.01.01" || $pay_method[$p]{pay_method} eq "1003.01.02") {#fanzy@2012-6-27	POS�����������п��ŵ�
									$pay_method[$p]{ReferNo}=~ s/\s*//g;$pay_method[$p]{ReOp_date}=~ s/\s*//g;$pay_method[$p]{ReOp_date}=~ s/\|//g;
									$pay_method[$p]{BankName}=~ s/\s*//g;$pay_method[$p]{BankName}=~ s/\|//g;$pay_method[$p]{BankCardNo}=~ s/\s*//g;$pay_method[$p]{BankCardNo}=~ s/\|//g;
									my $Pay_string;my $Pay_trans;
									$Pay_string=$pay_method[$p]{ReferNo};
									$Pay_trans=$pay_method[$p]{ReOp_date}."|".$pay_method[$p]{BankName}."|".$pay_method[$p]{BankCardNo};
									my $Comments=" ���ײο���:$pay_method[$p]{ReferNo};��������:$pay_method[$p]{ReOp_date};������:$pay_method[$p]{BankName};���ź�4λ:$pay_method[$p]{BankCardNo}";
									$sql_upt .= "insert into ctninfo..Airbook_pay_$Top_corp(Reservation_ID,Res_serial,Last_name,Pay_serial,Pay_object,
											Price_total,Recv_total,Left_total,User_ID,Operate_time,Comment,Corp_ID,Op_type,
											Ticket_time,Sales_ID,Operate_date,Person_num,Pay_trans,Pay_bank,CID_corp,Pre_recv,Pay_string)
										select '$res_id',$res_tmp_id,'$last_tmp_id',Isnull(max(Pay_serial),0)+1,'$pay_method[$p]{pay_method}',
											$must_recv,$once_price,0,'$in{User_ID}',getdate(),'��������$Comments$Operate_msg','$Corp_ID',\@op_type,
											'$ticket_tmp_id','$Corp_center',$Operate_date,1,'$Pay_trans','$pay_method[$p]{Pay_type2}','$bk_corp',sum(Recv_total),'$Pay_string'
										from ctninfo..Airbook_pay_$Top_corp 
										where Reservation_ID='$res_id' 
											and Res_serial=$res_tmp_id 
											and Last_name='$last_tmp_id' \n ";
								}else {
									my $sub_comment="''";
									my $Pay_string="'$pay_method[$p]{pingzheng}'";
									if ($pay_method[$p]{pingzheng} ne "") {
									
										$sub_comment ="' ƾ֤��$pay_method[$p]{pingzheng}'";
									}
									if ($tpsck_tradeno ne "") {
										$Pay_string=$tpsck_tradeno;
									}
									if ($tpsck_tradeno2 ne "") {
										$sub_comment=$tpsck_tradeno2;
									}
									
									#�Զ����������ֵ�������� ,��¼��ÿ��������¼���Ա���ѯ  liangby@2016-12-29
									if ($in{sxk_credit}>0 && $center_airparm=~/g/) {
										$Operate_msg .=",������$in{sxk_credit}��ֵ��������";
									}
									$sql_upt .= "insert into ctninfo..Airbook_pay_$Top_corp(Reservation_ID,Res_serial,Last_name,Pay_serial,Pay_object,
											Price_total,Recv_total,Left_total,User_ID,Operate_time,Comment,Corp_ID,Op_type,
											Ticket_time,Sales_ID,Operate_date,Person_num,Pay_trans,Pay_bank,CID_corp,Pre_recv,Pay_string)
										select '$res_id',$res_tmp_id,'$last_tmp_id',Isnull(max(Pay_serial),0)+1,'$pay_method[$p]{pay_method}',
											$must_recv,$once_price,0,'$in{User_ID}',getdate(),'��������$Operate_msg'+$sub_comment,'$Corp_ID',\@op_type,
											'$ticket_tmp_id','$Corp_center',$Operate_date,1,$Pay_string,'$pay_method[$p]{Pay_type2}','$bk_corp',sum(Recv_total),'$pay_method[$p]{pingzheng}'
										from ctninfo..Airbook_pay_$Top_corp 
										where Reservation_ID='$res_id' 
											and Res_serial=$res_tmp_id 
											and Last_name='$last_tmp_id' \n ";
								}
								##ͬһ�������ۼ�Ӧ�ս��   liangby@2017-2-14
								$must_recv_dt{"$res_id,$res_tmp_id,$last_tmp_id"}=$must_recv_dt{"$res_id,$res_tmp_id,$last_tmp_id"}-$once_price;
								$left=sprintf("%.2f",$must_recv-$once_price);
								
							
								my $old_cidcorp;
								$sql_tt=" select  datediff(day,Operate_date,getdate()),Recv_total,CID_corp,User_ID 
								    from ctninfo..Airbook_pay_$Top_corp where Reservation_ID='$res_id' 
										and Res_serial=$res_tmp_id 
										and Last_name='$last_tmp_id'  and Op_type in ('H','G') order by Operate_time";
								
								my $old_pay_num=0; my $current_pay_num=0; my $current_recv=0;
								my $gz_user="N";
								$db->ct_execute($sql_tt);
								while($db->ct_results($restype) == CS_SUCCEED) {
									if ($restype==CS_ROW_RESULT)	{
										while(@row = $db->ct_fetch)	{
											if ($row[0]==0) {##����
												$current_pay_num ++;
												if ($row[1] !=0) {
													$current_recv ++;  ##�����������¼
												}
												#$old_cidcorp=$row[2];
											}elsif($row[0] >0){
												$old_pay_num ++;
												#$old_cidcorp=$row[2];
											}
											if ($row[3] ne "SYSTEM") {##��ϵͳ�Զ�Ƿ��   liangby@2014-3-11
												$gz_user="Y";
											}
											
										}
									}
								}
								my $can_kq="N";  ##�������ٴ�Ƿ��
								if (($Corp_center eq "ESL003" || $Corp_center eq "CZZ259") &&  $gz_user eq "N") {
									$can_kq="Y";
								}
								##����CID�����¼   liangby@2013-1-26
								my $fc_corp_today;
								$sql_tt =" select * from ctninfo..Airbook_pay_$Top_corp where Reservation_ID='$res_id' and Res_serial=$res_tmp_id 
												 and Last_name='$last_tmp_id' and Op_type='C' and Operate_date=convert(char(10),getdate(),102) ";
								$db->ct_execute($sql_tt);
								while($db->ct_results($restype) == CS_SUCCEED) {
									if ($restype==CS_ROW_RESULT)	{
										while(@row = $db->ct_fetch)	{
											$fc_corp_today="Y";
										}
									}
								}
								my $kq_payname;  ##Ƿ���Ŀ���������ι����ǰ��ֽ�ȸ����Ŀ�ҵ�   liangby@2013-7-26
								if ($kemu_hash{$pay_method[$p]{pay_method}}[0] ne "") {
									$kq_payname=$kemu_hash{$pay_method[$p]{pay_method}}[0]." ";
								}
								if($old_pay_num==0 && $current_pay_num>0){##�����м�¼����ǰû��¼,��ǰ��Ƿ����0   liangby@2010-12-06
									if ($once_price==0) {##���ȫ��Ƿ���д��¼
										$left=0;
									}
									if ($current_recv >0 && $Pay_version eq "1") {
										$org_recv=0;   ##Ӧ��Ϊ0
									}
									 
								}elsif($old_pay_num >0 && $current_pay_num>=0){##��ǰ�м�¼������û��¼,����,����Ƿ����Ϊ0
								   if ($can_kq ne "Y") {
									   $org_recv=0;   ##Ӧ��Ϊ0��ʵ�ղ�Ϊ0��Ƿ��Ϊ0
									   if ($fc_corp_today ne "Y" ) {##��CID�����¼�ģ���������   liangby@2013-1-26
											 $left=0;
									   }
								   }
								   if ($once_price==0 && $can_kq ne "Y") {##���ȫ��Ƿ���д��¼
									  $left=0;
								   }
								   
								}
								if ($left !=0) {
									my $pay_type3=$pay_method[$p]{pay_method};
									
									if ($Pay_version eq "1" ) {##���˵İ�ԭ����Ŀ���ˣ������İ���ʱǷ�����   liangby@2010-12-15
										if ($pre_kemu_hash{$pre_pay_by}[3] eq "T") {##����
											if ($pre_kemu_hash{$pre_pay_by}[2] ne "") {
												$pay_type3=$pre_kemu_hash{$pre_pay_by}[2];
											}else{
												$pay_type3="1004.03.03";
											}
											
										}else{
											$pay_type3="1004.03.03";
										}
										if ($CERT_TYPE eq "Y") {
											$pay_type3="Y1131";	## ���ѣ�ֱ�ӹ� 1131-Ӧ���˿�	liangby@2013-12-16
										}
									}
									my $org_recv_left=0;
									if ($once_price==0) {
										$org_recv_left=$must_recv;
									}
									$sql_upt .= "insert into ctninfo..Airbook_pay_$Top_corp(Reservation_ID,Res_serial,Last_name,Pay_serial,Pay_object,
										Price_total,Recv_total,Left_total,User_ID,Operate_time,Comment,Corp_ID,Op_type,
										Ticket_time,Sales_ID,Operate_date,CID_corp,Pre_recv,Pay_bank)
									select '$res_id',$res_tmp_id,'$last_tmp_id',Isnull(max(Pay_serial),0)+1,'$pay_type3',
										$org_recv_left,0,$left,'$in{User_ID}',getdate(),'$kq_payname$in{Comment}$Operate_msg','$Corp_ID','G',
										'$Ticket_time','$Corp_center',$Operate_date,'$bk_corp',sum(Recv_total),''
									from ctninfo..Airbook_pay_$Top_corp 
									where Reservation_ID='$res_id' 
										and Res_serial=$res_tmp_id 
										and Last_name='$last_tmp_id' \n ";
								}
								$t_recv_total +=$once_price;						
								$sql_upt .= "update ctninfo..Airbook_$Top_corp set Recv_total=Recv_total+$once_price where Reservation_ID='$res_id' \n";
							}
						}
					}
				}
				if ($left_total !=0 && $t_recv_total==0) {##������Ӧ��Ŀʵ��Ϊ0������    liangby@2016-1-12
					next;
				}
				$rmk_ms=5*$p+15; ##����ʱ��
				$sql_upt .="insert into ctninfo..Res_op values('$res_id','A','$in{User_ID}','H',dateadd(ms,$rmk_ms,getdate())) \n ";
				my $book_status_str;
				if ($old_status eq "S") {
					$book_status_str .=",Book_status='H'";
				}
				
				if (($old_delivery_method eq "N" || $in{Is_voucher} eq "S")&& ($is_refund eq "1" || $is_refund eq "2" )) {
					##���跢Ʊ����Ʊ���Զ����Ϊ���ջط�Ʊ   liangby@2012-10-16
					$book_status_str .=",Is_voucher='S'";
					##�ջط�Ʊʱ�����Ʊ�����ǿգ�����   liangby@2012-7-6
					$sql_upt .=" update ctninfo..Airbook_$Top_corp set Send_date=getdate() where Reservation_ID='$res_id' and Send_date=null \n";
					$c_sql = "";
				}
				if ($old_otherfee !=0 && $t_recv_total !=0) {##��������ͬ������  liangby@2017-4-13
					$sql_tt = "SELECT a.Res_ID, a.Inc_id, a.Out_price, a.Pro_num FROM ctninfo..Inc_book AS a
							WHERE a.Sales_ID='$Corp_center'  AND a.Air_resid='$res_id' AND a.Order_type IN ('A','I') AND a.Book_status<>'H'";
					$db->ct_execute($sql_tt);
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT) {
							while(@row = $db->ct_fetch) {
								my $inc_resid = $row[0];
								my $inc_recv_price = $row[2] * $row[3];
								$sql_upt .= "update ctninfo..Inc_book set Recv_total=Recv_total+$inc_recv_price,Book_status='H',Pay_method='$pay_method[$p]{pay_method}',Pay_user='$in{User_ID}',Pay_date=convert(char(10),getdate(),102) where Res_ID='$inc_resid'\n";
							}
						}
					}
				}
				my $pay_kemu=$pay_method[$p]{pay_method};
				my $pay_bank=$pay_method[$p]{Pay_type2};
				my $sql_sxk="";
				$sxk_id=$pay_kemu.$pay_bank.$pay_method[$p]{pingzheng};
				#print qq`$res_id,$sxk_id,$bk_corp ne $Corp_center && $is_used{$sxk_id} eq "Y" && $payment_rmk_tp{$sxk_id} ne "",$cp_sno{$sxk_id}<br>\n`;

				if ( $bk_corp ne $Corp_center && $is_used{$sxk_id} eq "" && $p_sh_recv>0 && $t_recv_total !=0) {##���������   liangby@2015-6-11
					$is_used{$sxk_id}="Y"; ##�����������������жϣ�һ����Ŀ+������Ŀ+ƾ֤�ŵ�������ֻ����һ����¼    liangby@2015-11-12
					## t_recv_totalȡ��,�� p_sh_recv
					my $rt_result=&use_credit_payment($bk_corp,$pay_kemu,$pay_bank,$pay_method[$p]{pingzheng},$p_sh_recv,$res_id,$kemu_hash{$pay_kemu}[0],$kemu_hash{$pay_bank}[0],$p_sh_recv,"��������,����$res_id���$t_recv_total","0","Y");
					if ($rt_result=~/<error>/) {
						$rt_result=~ s/<error>//g;
						$rt_result=~ s/<\/error>//g;
						&write_log_account("��Ʊ��������:$res_id:$rt_result");
						print MessageBox("������ʾ","�Բ���$rt_result"); 
						exit;
					}else{
						$sql_upt .=$rt_result;
						my $payment_str;
					
						if ($rt_result=~/Corp_credit_payment/) {

							$payment_str="[ʹ�����������]";
							$paykemu_tp=$pay_kemu;
						
							$pay_bank_tp=$pay_bank;
							$trade_no_tp=$pay_method[$p]{pingzheng};
							$payment_rmk_tp{$sxk_id}=$payment_str.",�Ͷ���$res_idͬ������";
							$sql_upt .= "update ctninfo..Airbook_pay_$Top_corp set Comment=str_replace(Comment,'$payment_str',null)+'$payment_str'+',������ۿ��¼id:$bk_corp'+'_'+convert(varchar,\@s_no),Pay_status='SS'
								where Reservation_ID='$res_id' 
								   and Pay_object='$pay_kemu' and Pay_bank='$pay_bank' 
								   and CID_corp='$bk_corp' and Pay_trans='$pay_method[$p]{pingzheng}' and Operate_date=convert(char(10),getdate(),102) \n 
								delete from #tmp \n
								insert into #tmp(S_no) values(\@s_no) \n ";
						}
					}
				}elsif($bk_corp ne $Corp_center && $is_used{$sxk_id} eq "Y" && $payment_rmk_tp{$sxk_id} ne ""){
					$sql_upt .=" declare \@s_no int \n
						   select top 1  \@s_no=S_no from #tmp \n";
					$sql_upt .= "update ctninfo..Airbook_pay_$Top_corp set Comment=str_replace(Comment,'$payment_rmk_tp',null)+'$payment_rmk_tp{$sxk_id}'+',������ۿ��¼id:$bk_corp'+'_'+convert(varchar,\@s_no),Pay_status='SS'
								where Reservation_ID='$res_id' 
								   and Pay_object='$pay_kemu' and Pay_bank='$pay_bank' 
								   and CID_corp='$bk_corp' and Pay_trans='$pay_method[$p]{pingzheng}' and Operate_date=convert(char(10),getdate(),102) \n ";
					
					#if ($cp_sno{$sxk_id} ne "") {
						##����������ۿ��¼��ע˵��  liangby@2015-12-10
						$sql_upt .=" 
						   if \@s_no !=NULL 
						    BEGIN
							update ctninfo..Corp_credit_payment set Remark=Remark+',����$res_id���$t_recv_total' where Sales_ID='$Corp_center' and Corp_ID='$bk_corp' and S_no=\@s_no and Op_type='1' 
							END \n";
			
					#}
					
				}

				$Comment_str="";
				if ($pay_rescount==0 && $in{Comment} ne "") {
					$Comment_str=",Comment='$in{Comment} |'+Comment";
					if ($in{is_rmk} eq "Y") {##ǩע
						$rmk_status="1";
						if ($in{is_shows} eq "Y") {##��ʾ�����͵�
							$rmk_status="11";
						}
						$sql_upt .="insert into ophis..Op_rmk values('$res_id','$Corp_center','$in{User_ID}',getdate(),'$rmk_status','A','$in{Comment}','$Corp_ID') \n";
						if ($old_Tag_str !~/R/) {
							$Comment_str.=",Tag_str = rtrim(Tag_str)+'R'";
						}
					}
				}
				
				$sql_upt .= "update ctninfo..Airbook_$Top_corp set Pay_method='$pay_type_t',Left_total=Agt_total+Insure_out+Other_fee+isnull(Service_fee,0)-Recv_total,
					Pay_user='$in{User_ID}',Pay_date=convert(char(10),getdate(),102),Is_pay='Y',First_paydate=Isnull(First_paydate,convert(char(10),getdate(),102)),Is_urgent='N'$c_sql $book_status_str $Comment_str where Reservation_ID='$res_id' \n";
				if ($bk_corp ne $Corp_center) {
					$sql_p = "select Pay_amount from ctninfo..Airbook_unpay where Reservation_ID='$res_id' and Corp_ID='$bk_corp' ";
					my $unpay_amount;
					$db->ct_execute($sql_p);
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT)	{
							while(@row = $db->ct_fetch)	{
								$unpay_amount=$row[0];
							}
						}
					}
					if ($unpay_amount != 0) {	## ��Ҫ�������ö�Ȼ���¶��
						$sql_upt .= " declare \@l_credit decimal(10,2) \n
						declare \@unpay_amount decimal(10,2) \n
						select \@unpay_amount=Pay_amount from ctninfo..Airbook_unpay where Reservation_ID='$res_id' and Corp_ID='$bk_corp' \n
						select \@l_credit=case when AAboook_method='T'  then Out_total+Other_fee+Insure_out+isnull(Service_fee,0)-Recv_total else Agt_total+Other_fee+Insure_out+isnull(Service_fee,0)-Recv_total end 
								from ctninfo..Airbook_$Top_corp where Reservation_ID='$res_id' \n
						if \@l_credit=0
						begin
							 update ctninfo..Corp_credit set Credit_used=Credit_used+(-1*\@unpay_amount) where Ticket_ID='$Corp_center' and Corp_ID='$bk_corp' and History=0  
							delete from ctninfo..Airbook_unpay where Reservation_ID='$res_id' and Corp_ID='$bk_corp' \n
							update ctninfo..Airbook_$Top_corp set Is_pay='Y' where Reservation_ID='$res_id' \n
						end 
						else
						begin
							update ctninfo..Airbook_unpay set Pay_amount=\@l_credit,ET_price=\@l_credit,Status='N' where Reservation_ID='$res_id' and Corp_ID='$bk_corp' \n
							update ctninfo..Corp_credit set Credit_used=Credit_used+(-1*\@unpay_amount)+\@l_credit where Corp_ID='$bk_corp' and Ticket_ID='$Corp_center' and History=0 \n
						end \n
						if exists(select  Corp_ID from ctninfo..Corp_credit where Corp_ID='$bk_corp' and Ticket_ID='$Corp_center' and History=0 and Credit_used <Credit_total )
						   begin
								update ctninfo..Corp_credit set Credit_temp=0 where Corp_ID='$bk_corp' and Ticket_ID='$Corp_center' and History=0
						   end
						   else
						   begin
								if exists(select  Corp_ID from ctninfo..Corp_credit where Corp_ID='$bk_corp' and Ticket_ID='$Corp_center' and History=0 and Credit_used >Credit_total and Credit_temp >0 )
								begin
									update ctninfo..Corp_credit set Credit_temp=Credit_used-Credit_total where Corp_ID='$bk_corp' and Ticket_ID='$Corp_center' and History=0
								end
						   end \n ";
					}
				}
				##ͣ��    liangby@2016-1-12
#				if (($Corp_center eq "ESL003" || ($Corp_center eq "TYN210" && $bk_corp eq "ZGYDTX")) && ( $old_status eq "S" || $old_status eq "H") ) {
#					##̫ԭ�θۻ���������   liangby@2011-6-27
#					my $ws_tag="1";  ##1�ƶ�
#					$sql_upt .=" if not exists(select * from ctninfo..TYN_data_temp where Reservation_ID='$res_id' and Send_type='2' )
#							begin
#							   insert into ctninfo..TYN_data_temp(Reservation_ID,Sales_ID,Corp_ID,Send_status1,Send_status2,WS_tag,Op_time,Send_type)
#								values('$res_id','$Corp_center','$bk_corp','0','0','$ws_tag',getdate(),'2')
#							end";
#				}
				if ($t_recv_total>0 && ($is_refund eq "0" || $is_refund eq "3") && $Corp_center eq "SJW121") {
					##����Ƿ����ô����   liangby@2015-1-30
					$sql_tt=" select CCP_no  from ctninfo..CCP_voucher where Sales_ID='$Corp_center' 
						and User_ID='$user_id' and Res_ID='$res_id' ";
					my @old_ccp_no=();
					$db->ct_execute($sql_tt);
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT) {
							while(@row = $db->ct_fetch) {
								push(@old_ccp_no,$row[0]);
							}
						}
					}
					my $old_ccp_no=join("','",@old_ccp_no);
					my $cpp_num=0;
					if ($old_ccp_no ne "") {
						$sql_tt=" select count(*) from ctninfo..Airbook_pay_$Top_corp where Reservation_ID='$res_id' and Pay_object='4003.01.03' and Recv_total>0 and Pay_string in ('$old_ccp_no') ";
						$db->ct_execute($sql_tt);
						while($db->ct_results($restype) == CS_SUCCEED) {
							if($restype==CS_ROW_RESULT) {
								while(@row = $db->ct_fetch) {
									$cpp_num=$row[0];
								}
							}
						}
					}
					if ($cpp_num >0) {
						&write_log_account("��Ʊ��������:$res_id:ʹ���˴����,ֻ������֧��,�����̨��Ƿ,��ɾ��������¼");
						print MessageBox("������ʾ","����$res_idʹ���˴����,ֻ������֧��,�����̨��Ƿ,��ɾ��������¼"); 
						exit;
					}
				}
				my %m_type = &get_dict($Corp_center,1,"","hash");
				if (grep {$_ eq $bk_type} keys %m_type){
					##���ֵֿ�   liangby@2012-10-23
					
					if ($t_recv_total !=0  && $pay_method[$p]{pay_method} eq "4003.01.04") {##���ֵֿ�    liangby@2012-10-23
						$tt_usertype=$bk_type;
						if ($bk_type eq "N") {
							$tt_usertype="C";
						}
						my $reward_dk;
						my $Apply_ID;
						$sql_tt="select Reward_rate,right(convert(char(10),getdate(),102),8) from ctninfo..Reward_rate where Corp_ID='$Corp_center' and Product_type='R' and User_type='$tt_usertype' ";
						
						$db->ct_execute($sql_tt);
						while($db->ct_results($restype) == CS_SUCCEED) {
							if($restype==CS_ROW_RESULT)	{
								while(@row = $db->ct_fetch)	{
									$reward_dk=$row[0];    ##��ֻ�һԪ
									$Apply_ID=$row[1];
									$Apply_ID =~ s/\.//g;
								}
							}
						}
						if ($reward_dk eq "" || $reward_dk==0) {
							
							print MessageBox("������ʾ","�Բ���,����$res_id��Ա������δά�����ֵֿ����ѽ�����,���ڻ��ֹ�����ά��"); 
							&write_log_account("��Ʊ��������:$res_id:��Ա������δά�����ֵֿ����ѽ�����,���ڻ��ֹ�����ά��");
							exit;
						}
					
						##����Ҫ����
						$need_reward=sprintf("%0.f",$t_recv_total*$reward_dk);
						my $u_left=0;
						##�ĴӼ�¼��ʵʱ��ȡ�ܻ��ֺ����û���    liangby@2014-6-26
						my $Total_reward=0;
						$sql_tt =" select isnull(sum(Reward),0) from ctninfo..Member_reward where User_ID='$user_id' and Corp_num='$Corp_center' ";
						$db->ct_execute($sql_tt);
						while($db->ct_results($restype) == CS_SUCCEED) {
							if($restype==CS_ROW_RESULT)	{
								while(@row = $db->ct_fetch)	{
									$Total_reward=$row[0];
								}
							}
						}
						my $Pay_reward=0;
						$sql_tt=" select isnull(sum(Gift_num*Need_reward),0) from ctninfo..Gift_apply where Corp_num='$Corp_center' and User_ID='$user_id' and De_status <>'C' ";
						$db->ct_execute($sql_tt);
						while($db->ct_results($restype) == CS_SUCCEED) {
							if($restype==CS_ROW_RESULT)	{
								while(@row = $db->ct_fetch)	{
									$Pay_reward=$row[0];
								}
							}
						}
						$u_left=$Total_reward-$Pay_reward;
						if ($u_left <$need_reward) {
							if ($Corp_center eq "022000" && $in{User_ID} eq "hx001") {##��Ѷ���ܿ��Եֿ۸����֣��ź�Ҫ��   liangby@2012-10-25
							}else{
								print MessageBox("������ʾ","�Բ���,��$res_id��Աʣ����ֲ���,�������$need_reward,ʣ�����$u_left");
								&write_log_account("��Ʊ��������:$res_id:��Աʣ����ֲ���,�������$need_reward,ʣ�����$u_left");
								exit;
							}
						}
						my $tkt_name;
						if ($is_refund eq "1" || $is_refund eq "2") {
							$tkt_name=",�˷�Ʊ";
						}
						$sql_upt .= " declare \@Apply_ID integer 
							select \@Apply_ID = max(convert(integer,Apply_ID))+1 from ctninfo..Gift_apply where Apply_ID like '$Apply_ID%'
							if \@Apply_ID=null select \@Apply_ID = $Apply_ID * 1000
							INSERT INTO ctninfo..Gift_apply (Corp_num,Corp_ID,User_ID,Apply_ID,Gift_ID,
									Gift_name,Gift_num,Need_reward,Apply_date,Delivery_method,De_person,
									De_address,De_zip,De_tel,De_email,De_status,Comment,Apply_by,Apply_time,Gift_no,APrice,Confirm_by,Confirm_time)
							VALUES ('$Corp_center','$Corp_ID','$user_id',convert(varchar(9),\@Apply_ID),-1,
									'��Ʊ�������ֵֿ�$t_recv_totalԪ$tkt_name,�ֿ�ǰʣ�����$u_left',1,$need_reward,getdate(),'Q','',
									'','','','','Y','��Ʊ�������ֵֿ�$t_recv_totalԪ$tkt_name,�ֿ�ǰʣ�����$u_left','$in{User_ID}',getdate(),'$res_id',$t_recv_total,'$in{User_ID}',getdate()) \n";
						##ͬ���Ѷһ�����  liangby@2014-5-14
						$sql_upt .= " update ctninfo..User_info set Pay_reward=(select isnull(sum(Gift_num*Need_reward),0) from ctninfo..Gift_apply where Corp_num='$Corp_center' and User_ID='$user_id' and De_status <>'C' ) where Corp_num='$Corp_center' and User_ID='$user_id' \n";

					}
					##---------------
					$reward_cmt="����";
					if ($Air_type eq "Y") {##���ʻ�Ʊ     liangby@2008-7-8
						$Air_type="B";	$reward_cmt="����"	
					}else{
						$Air_type="A";
					}
					### �����ţ��������ͣ�A���ڻ�Ʊ/B���ʻ�Ʊ���������ģ�����Ա����Ա���룬��Ա���ͣ�֧����ʽ��֧����ע,֧�����
					##������Ÿ�����    liangby@2017-4-6
					my $sql_reward =&account_reward($res_id,$Air_type,$Corp_center,$in{User_ID},$user_id,$bk_type,$pay_type_t,"","");
					if ($sql_reward ne "") {
						$sql_upt .=" if (select case when AAboook_method='T'  then Out_total+Other_fee+Insure_out+isnull(Service_fee,0)-Recv_total else Agt_total+Other_fee+Insure_out+isnull(Service_fee,0)-Recv_total end 
							from ctninfo..Airbook_$Top_corp where Reservation_ID='$res_id')=0 \n BEGIN "; 
						$sql_upt .=$sql_reward;
						$sql_upt .=" END\n";
						if ($is_refund eq "0") {
							$reward_resid{$res_id}{user_id}=$user_id;
							$reward_resid{$res_id}{bk_corp}=$bk_corp;
							$reward_resid{$res_id}{Mobile}=$Mobile;
						}
					}
					
					
					
				}
				if ($pay_method[$p]{pay_method} eq "4003.01.03" && $pay_method[$p]{pingzheng} ne "" && $pay_method[$p]{pingzheng_other} ne "") {
					$sql_upt .= "Update ctninfo..CCP_voucher set Status='U',Use_time=getdate(),Res_ID='$res_id',Is_sms='N',P_no='$last_tmp_id' where Sales_ID='$Corp_center' and CCP_no='$pay_method[$p]{pingzheng}' and User_ID='$user_id' \n";
					if ($CCP_no_list ne "") {$CCP_no_list.=",";}
					$CCP_no_list.=$pay_method[$p]{pingzheng};$CCP_Amount_total+=$pay_method[$p]{Pay_Recv_total};
				}
				
				#if ($in{User_ID} eq "admin") {
				#	print "<pre>$sql_upt";
				#	exit;
				#}
				## Alert_status==0��������
				if( $is_refund ==0 && $tkt_diff==0 && ($old_status eq "S" || $old_status eq "H" || $old_status eq "P") && ($Corp_center eq "CZZ259" || $Corp_center eq "ESL003")){ ## �ӱ���ʱ�Զ�����������Ʒ����Ȼ���Զ����� dingwz@2014-06-13
				 
					
					#local($order_id_str,$user_id,$ic_id,$pay_type,$buy_type,$trade_no,$pay_bank)=@_;
					my $insure_book_resok =&inc_insure_book_resok($res_id,$user_id,$in{inc_insure_type},$pay_method[$p]{pay_method},$in{inc_insure_buy_type},$pay_method[$p]{pingzheng},$pay_method[$p]{Pay_type2});
					my $xml_result=@{&getXMLValue("RESULT", $insure_book_resok)}[0];
					if($xml_result eq "SUCCESS"){
						my $xml_sql=@{&getXMLValue("SQL",$insure_book_resok)}[0];
						my $xml_price=@{&getXMLValue("PRICE",$insure_book_resok)}[0];
						$sql_upt .= $xml_sql;
						$total_use += $xml_price;
					}else{
						my $xml_error=@{&getXMLValue("ERROR",$insure_book_resok)}[0];
						print MessageBox("������ʾ", "$xml_error"); 
						&write_log_account("��Ʊ��������:$res_id:$xml_error");
						exit;
					}
				}
			
#				print "<pre>$sql_upt<br>\n";exit;
			    push(@sql_array,$sql_upt);
#				my ($sms_pay,$sms_reward,$sms_total,$sms_pay)=();
#				my $Update = 0;
#				$db->ct_execute($sql_upt);
#				while($db->ct_results($restype) == CS_SUCCEED) {
#					if($restype==CS_CMD_DONE) {
#						next;
#					}elsif($restype==CS_COMPUTE_RESULT) {
#						next;
#					}elsif($restype==CS_CMD_FAIL) {
#						$Update = 0;		
#						next;
#					}elsif($restype==CS_CMD_SUCCEED) {
#						$Update = 1;			
#						next;
#					}
#					elsif($restype==CS_ROW_RESULT) {
#						while(@row = $db->ct_fetch) {
#							if (scalar(@row)==1 && $payment_rmk_tp{$sxk_id} ne "") {##������ۿ��¼
#								$cp_sno{$sxk_id}=$row[0];
#							   #  $cp_sno=$row[0];
#							}else{
#								($sms_pay,$sms_reward,$sms_total,$sms_pay) = @row;
#								$sms_total = $sms_total-$sms_pay;
#							}
#						}
#					}	
#				}
#				if($Update eq '1') {
#					$db->ct_execute("Commit Transaction sql_insert");
#					#$db->ct_execute("Rollback Transaction sql_insert");
#					while($db->ct_results($restype) == CS_SUCCEED) {
#						if($restype==CS_ROW_RESULT) {
#							while(@row = $db->ct_fetch) {
#							}
#						}
#					}
#					if (grep {$_ eq $bk_type} keys %m_type){
#						## ��鵱ǰ�û��Ƿ�ͨ���Ź���
#						$sql = "select Sms_acl from ctninfo..User_info where User_ID='$in{User_ID}'";
#						$sms_acl = &Exec_sql();
#						##���ͻ��ֶ���    liangby@2012-4-12
#						if ($sms_reward > 0  && $is_refund == 0 && $sms_acl eq "Y") {	## �л�����û���˷�Ʊ���ż���Ƿ��ͻ��ֶ���
#							## ---------------------------------------------
#							## ��ѯ���ֶ���ģ��
#							## ����ȡ����������˾�Ķ���ģ�壬�����������ȡ���� jeftom @2010-04-08
#							## ---------------------------------------------
#							$sql_tt = "IF EXISTS(select Is_auto from ctninfo..Sms_type where Corp_ID='$bk_corp' and Sms_type='M')
#										BEGIN
#											select Content,Is_auto from ctninfo..Sms_type where Corp_ID='$bk_corp' and Sms_type='M'
#										END
#									ELSE
#										BEGIN
#											select Content,Is_auto from ctninfo..Sms_type where Corp_ID='$Corp_center' and Sms_type='M'
#										END";
#							my $Is_auto;
#							$db->ct_execute($sql_tt);
#							while($db->ct_results($restype) == CS_SUCCEED) {
#								if($restype==CS_ROW_RESULT)	{
#									while(@row = $db->ct_fetch)	{
#										$sms_format = $row[0];	$Is_auto=$row[1];
#									}
#								}
#							}
#							if ($Is_auto eq "Y") {
#								$sql = "select Corp_csname,Tel,Homepage from ctninfo..Corp_info where Corp_ID='$Corp_center' ";
#								$db->ct_execute($sql);
#								while($db->ct_results($restype) == CS_SUCCEED) {
#									if($restype==CS_ROW_RESULT)	{
#										while(@row = $db->ct_fetch)	{
#											($sms_corp,$sms_tel,$sms_homepage)=@row;
#										}
#									}
#								}
#								$sms_format =~ s/%c/$sms_corp/g;
#								$sms_format =~ s/%n//g;
#								$sms_format =~ s/%t/$sms_tel/g;
#								$sms_format =~ s/%h/$sms_homepage/g;
#								$sms_format =~ s/%U/$user_id/g;
#								$sms_format =~ s/%f/$sms_reward/g;
#								$sms_format =~ s/%r/$sms_total/g;
#								my $a = &smsPost("N",$in{User_ID},$sms_format,$Mobile,'A',"getdate()","","M","","Y");
#								
#							}
#							
#						}
#					}
#					if ($CCP_no_list ne "" && $ccp_resid ne "" && $ccp_userid ne "" && $ccp_mobile ne "") {##���ʹ���ȯ����
#						my $sms_format="���ѳɹ�ʹ�ô����,���[$CCP_no_list]�����$CCP_Amount_total,������$ccp_resid";
#						$a = &smsPost("N",$ccp_userid,$sms_format,$ccp_mobile,'A',"getdate()","$ccp_resid","e");
#					}
#				}
#				else{
#					$db->ct_execute("Rollback Transaction sql_insert");
#					while($db->ct_results($restype) == CS_SUCCEED) {
#						if($restype==CS_ROW_RESULT) {
#							while(@row = $db->ct_fetch) {
#							}
#						}
#					}
#					print MessageBox("������ʾ","���� $res_id ��������ʧ��!");
#					&write_log_account("��Ʊ��������:$res_id:����д��ʧ��:$sql_upt");
#					exit;
#				}
#				$pay_rescount++;
			}
		}
	}
	#�Զ����������ֵ�������� fanzy@2015-11-26
	##�ŵ�ͬһ��������  liangby@2018-1-17
	if ($in{sxk_credit}>0 && $center_airparm=~/g/) {
		@bkcorp_arr = grep { ++$count{ $_ } < 2; } @bkcorp_arr;
		if (scalar(@bkcorp_arr)!=1) {
			&write_log_account("$Corp_center:$in{User_ID}:$in{sxk_credit},�������ֵʧ�ܣ����������ͻ���Ψһ".join(",",@bkcorp_arr));
			print MessageBox("������ʾ","�������ֵʧ�ܣ����������ͻ���Ψһ"); 
			exit;
		}else{
			&write_log_account("$Corp_center:$in{User_ID}:�ͻ� $bk_corp �ɹ���ֵ������ $in{sxk_credit}");
			my $bk_corp=$bkcorp_arr[0];
			my $pay_kemu="1003.02.25";my $pay_bank="6:31.1000";my $pingzheng="";
			## �޸�����
			$sql_tt=" select convert(char(10),getdate(),102),Contact_person,Tel,convert(varchar(8),getdate(),112)+convert(varchar(6),datepart(hh,getdate())*10000+datepart(mi,getdate())*100+datepart(ss,getdate())) from ctninfo..Corp_info where Corp_ID='$bk_corp' and Corp_num='$Corp_center' ";
			$db->ct_execute($sql_tt);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$resp_time=$row[0];
						$resp_time=~ s/[\.:\s]//g;
						$year=substr($resp_time,0,4);
						$corp_contact=$row[1];
						$corp_tel=$row[2];
						$pingzheng=$row[3];
					}
				}
			}
			##�������������ֹϵͳ�ĺ��뼶����ͬһ��cid   liangby@2018-1-18
			srand time();
			my $tt = rand(1);
			$tt=substr($tt,4,4); 
			$pingzheng=$pingzheng."_".$tt;
			##�����������ֵ��
			## �ȿ���û�з�����Ʒ 
			$Pro_id=26;
			$sql_tt=" select top 1 Inc_id,Tag_str from ctninfo..Inc_goods where Corp_ID='$Corp_center' and Pro_id=$Pro_id
				 and Status='Y'  ";
			my ($inc_id,$inc_tagstr)=();
			$db->ct_execute($sql_tt);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$inc_id=$row[0];
						$inc_tagstr=$row[1];
					}
				}
			}
			$sql_sxk = " declare \@Inc_resno2 varchar(15) \n
				select \@Inc_resno2='' \n ";
			if ($inc_id eq "") {##û�о��Զ�����
				$inc_tagstr="ABC";
				$inc_id="1";
				$sql_sxk.=qq! declare \@pr_id2 integer 
					 if exists (select * from ctninfo..Inc_goods where Corp_ID='$Corp_center') 
					select \@pr_id2=max(Inc_id)+1 from ctninfo..Inc_goods where Corp_ID='$Corp_center' 
					else select \@pr_id2=1 
				   insert into ctninfo..Inc_goods(Inc_id,Corp_ID,Pro_id,Inc_title,Address,In_price,Out_price,Start_date,End_date,
							Status,Use_obj,Total_num,Sales_num,Remark,Op,Op_time,Reward_rate,Delivery_method,Discount,Sp_corp,Tag_str,Other_fee,Book_comm,Us_inprice,Us_other_fee)
							values(\@pr_id2,'$Corp_center',$Pro_id,'�������ֵ��','',0,0,convert(char(10),getdate(),102),dateadd(yy,2,getdate()),
							'Y','012',0,0,'','SYSTEM',getdate(),0,'Q',0,
							'','ABC',0,0,'Y','Y') !;
			}
			my $res_head="3".substr($year,3,1);
			$sql_sxk .=qq! if not exists( select * from ctninfo..Corp_credit_payment where Sales_ID='$Corp_center' and Corp_ID='$bk_corp' and Pay_kemu='$pay_kemu'  and Trade_no='$pingzheng' and Op_type='0' )
			  BEGIN
				if not exists(select * from ctninfo..Inc_ResLimit where Agent_ID='$Corp_center' and Year='$year') 
				 BEGIN
					  insert into ctninfo..Inc_ResLimit(Agent_ID,Year,Number) values('$Corp_center','$year',0) 
				 END
				 Update ctninfo..Inc_ResLimit set Number=Number+1 where Agent_ID='$Corp_center' and Year='$year' 
				  select \@Inc_resno2='$res_head'+rtrim(b.Corp_CID)+
					stuff('000000',7-char_length(rtrim(convert(char(6),Number))),char_length(rtrim(convert(char(6),Number))),rtrim(convert(char(6),Number)))
					from ctninfo..Inc_ResLimit a,ctninfo..Corp_extra b
					Where a.Agent_ID=b.Corp_ID and a.Year='$year' and a.Agent_ID='$Corp_center'
				insert into ctninfo..Inc_book(Res_ID,Corp_ID,Book_corp,Agent_ID,Send_corp,Sales_ID,Inc_title,Inc_id,Pro_id,
						In_price,Out_price,Pro_num,Out_total,In_total,Recv_total,Contract,Tel,User_ID,Book_ID,Book_time,Pay_method,Is_op,
						Book_status,Other_fee,User_rmk,Delivery,S_date,S_time,Address,Remark,Sp_corp,Relate_ID,Effect_date,Tag_str,Book_comm,Air_resid,Ticket_by,Ticket_date) 
						values(\@Inc_resno2,'$bk_corp','$Corp_ID','$Corp_ID','$Corp_ID','$Corp_center','�������ֵ��',$inc_id,$Pro_id,
						$in{sxk_credit},$in{sxk_credit},1,$in{sxk_credit},$in{sxk_credit},0,'$corp_contact','$corp_tel','$in{User_ID}','$in{User_ID}',getdate(),'$pay_kemu','N',
						'H',0,'','N',convert(char(10),getdate(),102),'','','',' ','','','$inc_tagstr',0,'','$in{User_ID}',convert(char(10),getdate(),102)) \n
				 insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) values(\@Inc_resno2,'G','$$in{User_ID}','B',getdate()) \n
				INSERT INTO ctninfo..Inc_book_detail(Res_ID, Serial_no, Sales_ID, Cust_name, Card_ID, Status,Print_no)
											VALUES(\@Inc_resno2, 0, '$Corp_center', '', '', '0','') \n!;
			$sql_sxk .=" update ctninfo..Inc_book set Recv_total=Recv_total+$in{sxk_credit},Pay_method='$pay_kemu' where Res_ID=\@Inc_resno2 \n";
			
			$sql_sxk .=" insert into ctninfo..Inc_book_pay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,CID_corp,Pay_bank,Pay_status)
			   values(\@Inc_resno2,0,'$pay_kemu',$in{sxk_credit},$in{sxk_credit},0,'$in{User_ID}',getdate(),convert(char(10),getdate(),102),
				   '�������ֵ����','$pingzheng','$Corp_center','$Corp_ID','$bk_corp','','')  \n";
			
			$sql_sxk .=" insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) 
				values(\@Inc_resno2,'G','$in{User_ID}','I',getdate()) \n";
			
			$sql_sxk .= "insert into ctninfo..Corp_credit_payment(Sales_ID,Corp_ID,S_no,Amount,Amount_used,Mod_by,Mod_time,
					Remark,Op_type,Trade_no,Op_str,Pay_kemu,Pay_bank)
				select '$Corp_center','$bk_corp',Isnull(max(S_no),-1)+1,$in{sxk_credit},0,'$in{User_ID}',getdate(),
					'���������Զ���ֵ,'+\@Inc_resno2,'0','$pingzheng','','$pay_kemu',''
				from ctninfo..Corp_credit_payment where Sales_ID='$Corp_center' and Corp_ID='$bk_corp'  \n";
			$sql_sxk .=" END ";
			push(@sql_array,$sql_sxk);

		}
	}
    $sql_upt = " create table #tmp(S_no Int NULL) \n
	begin Transaction sql_insert  \n";
	#push(@sql_array,"drop table #tmp ");
#	$sql_upt .=join(" ",@sql_array);
#	print "<pre>$sql_upt</pre><br />";
#	exit;
#    for(my $t=0;$t<scalar(@sql_array);$t++){
#		print "<pre>$sql_array[$t]</pre><br />";
#    }
#	exit;
	$Update==0;
	$db->ct_execute($sql_upt);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_CMD_DONE) {
			next;
		}elsif($restype==CS_COMPUTE_RESULT) {
			next;
		}elsif($restype==CS_CMD_FAIL) {
			$Update=0;		
			next;
		}elsif($restype==CS_CMD_SUCCEED) {
			$Update=1;			
			next;
		}
		elsif($restype==CS_ROW_RESULT) {
			while(@row=$db->ct_fetch) {
			}
		}
	}
	if($Update eq '1') {
		if(scalar(@sql_array)>0){
			$Update=&write_array_to_db(\@sql_array,1);
			if($Update eq '1'){	
				&pt_auto_balance(\%resid_corp,\%resid_amount);	##���߻��ɹ�Ӧ�����ɹ����Զ���ֵ
			}
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
	}
	else{
		$db->ct_execute("Rollback Transaction sql_insert");
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row=$db->ct_fetch) {
				}
			}
		}
	}
	if ($Update==0) {
		for(my $t=0;$t<scalar(@sql_array);$t++){
			#print "<pre>$sql_array[$t]</pre><br />";
			$sql_upt .=$sql_array[$t];
		}
		&write_log_account("��Ʊ��������:$res_id:����д��ʧ��:$sql_upt");
		print MessageBox("������ʾ","�Բ�������д��ʧ��"); 
		exit;
	}
	$sc_msg="";
	$sc_msg2="";
	if($total_use ne ""){
		#print qq!<font style='color:blue;font-size:12px;'>�ɹ�����$total_use</font>!;
		$sc_msg .=qq!<font style='color:blue;font-size:12px;'>�ɹ�����$total_use</font>!;
		$sc_msg2 .="�ɹ�����$total_use,";
		if ($in{sxk_credit}>0 && $center_airparm=~/g/) {
			$sc_msg .= qq!<font style='color:blue;font-size:12px;'>�ͻ� $bk_corp �ɹ���ֵ������ $in{sxk_credit}</font>!;
			$sc_msg2 .=qq!�ͻ� $bk_corp �ɹ���ֵ������ $in{sxk_credit},!;
			
		}
	}else{
		#print qq!<font style='color:red;font-size:12px;'>��ѡ�񶩵���������</font>!;
		print MessageBox("������ʾ","�Բ�����ѡ�񶩵���������"); 
		exit;
	}
	
	##���ͻ��ֶ���
	@reward_resid=keys %reward_resid;
	foreach my $resid (@reward_resid) {
		$user_id=$reward_resid{$resid}{user_id};
		$bk_corp=$reward_resid{$resid}{bk_corp};
		$Mobile=$reward_resid{$resid}{Mobile};
		if($Mobile=~/[A-Z]$/){ $Mobile=&JieMi_ph($Mobile); }
		my $sms_reward;
		$sql_tt=" select Reward from ctninfo..Member_reward where User_ID='$user_id' and Corp_num='$Corp_center' and Res_ID='$resid' and Sale_type='A'  ";
		$db->ct_execute($sql_tt);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$sms_reward=$row[0];
				}
			}
		}
		my $sms_total;
		$sql_tt=" select Total_reward,Pay_reward from ctninfo..User_info where User_ID='$user_id' and Corp_num='$Corp_center' ";
		$db->ct_execute($sql_tt);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$sms_total=sprintf("%0.f",$row[0]-$row[1]);
				}
			}
		}
		## ��鵱ǰ�û��Ƿ�ͨ���Ź���
		$sql = "select Sms_acl from ctninfo..User_info_op where User_ID='$in{User_ID}' and Corp_num='$Corp_center' ";
		
		$sms_acl = &Exec_sql();
		
		##���ͻ��ֶ���    liangby@2012-4-12
		if ($sms_reward > 0   && $sms_acl eq "Y" && $Mobile=~/^(13|14|15|17|18)\d{9}$/) {	## �л�����û���˷�Ʊ���ż���Ƿ��ͻ��ֶ���
			## ---------------------------------------------
			## ��ѯ���ֶ���ģ��
			## ����ȡ����������˾�Ķ���ģ�壬�����������ȡ���� jeftom @2010-04-08
			## ---------------------------------------------
			$sql_tt = "IF EXISTS(select Is_auto from ctninfo..Sms_type where Corp_ID='$bk_corp' and Sms_type='M')
						BEGIN
							select Content,Is_auto from ctninfo..Sms_type where Corp_ID='$bk_corp' and Sms_type='M'
						END
					ELSE
						BEGIN
							select Content,Is_auto from ctninfo..Sms_type where Corp_ID='$Corp_center' and Sms_type='M'
						END";
			my $Is_auto;
			$db->ct_execute($sql_tt);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$sms_format = $row[0];	$Is_auto=$row[1];
					}
				}
			}
			
			if ($Is_auto eq "Y") {
				$sql = "select Corp_csname,Tel,Homepage from ctninfo..Corp_info where Corp_ID='$Corp_center' ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							($sms_corp,$sms_tel,$sms_homepage)=@row;
						}
					}
				}
				$sms_format =~ s/%c/$sms_corp/g;
				$sms_format =~ s/%n//g;
				$sms_format =~ s/%t/$sms_tel/g;
				$sms_format =~ s/%h/$sms_homepage/g;
				$sms_format =~ s/%U/$user_id/g;
				$sms_format =~ s/%f/$sms_reward/g;
				$sms_format =~ s/%r/$sms_total/g;
				my $a = &smsPost("N",$in{User_ID},$sms_format,$Mobile,'A',"getdate()","","M","","Y");
				
			}
			
		}
	}

	$sc_msg2=&uri_escape($sc_msg2);
	$Guest_name=&uri_escape($in{Guest_name});
	$username=&uri_escape($in{username});
	$team_name=&uri_escape($in{team_name});
	print &showMessage("ϵͳ��ʾ", "������ɣ�$sc_msg", "/cgishell/golden/admin/airline/res/air_account.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Order_type=$in{Order_type}&Op=$in{Op}&Corp_ID=$in{Corp_ID}&user_book=$in{user_book}&Start=1&air_type=$in{air_type}&Depart_date=$Depart_date&End_date=$End_date&Sender=$in{Sender}&History=$in{History}&his_year=$in{his_year}&pay_obj=$in{pay_obj}&Send_corp=$in{Send_corp}&hfcw=$in{hfcw}&Res_ID=$in{Res_ID}&cyewu=$in{cyewu}&tkt_id=$in{tkt_id}&sc_msg=$sc_msg2&parent_corp=$in{parent_corp}&re_other=$in{re_other}&date_type=$in{date_type}&Select_the=$in{Select_the}&PNR=$in{PNR}&PY_name=$in{PY_name}&userid=$in{userid}&mobile=$in{mobile}&Ticket_agent=$in{Ticket_agent}&Level_ID=$in{Level_ID}&account_type=$in{account_type}&Pay_method=$in{Pay_method}&ET_type=$in{ET_type}&Guest_name=$Guest_name&username=$username&team_name=$team_name", "", 0, "3000");
	&Footer();
	
	exit;


}
## ==============

## ����Ƿ��  likunhua@2009-02-26
sub air_account_debt {
	if ($Pay_version eq "1") {
		##��ȡ��ƿ�Ŀ����Ϣ��ϣ��  liangby@2010-12-11
		%kemu_hash = &get_kemu($Corp_center,"","hash2","");

	}
	my $kq_payname;  ##Ƿ���Ŀ���������ι����ǰ��ֽ�ȸ����Ŀ�ҵ�   liangby@2013-7-26
	if ($kemu_hash{$in{pay_method}}[0] ne "") {
		$kq_payname=$kemu_hash{$in{pay_method}}[0]." ";
	}
	for ($i=0;$i<$in{t_num};$i++) {
		my	$cb="cb_$i";	my $res_id=$in{$cb};
		if ($res_id ne "") {	## ѡ�еĶ���
			$sql = "select b.User_ID,b.Book_status,b.Corp_ID,b.Send_date,b.If_out,rtrim(b.Pay_method),convert(char(10),b.Ticket_time,102),b.Alert_status,b.Old_resid from ctninfo..Airbook_$Top_corp b
					where b.Sales_ID='$Corp_center' and b.Reservation_ID='$res_id' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						($user_id,$old_status,$bk_corp,$cust_pay_date,$if_out,$old_pay,$old_ticket_time,$is_refund,$old_resid)=@row;
					}
				}
			}
			if (($is_refund eq "1" || $is_refund eq "2")
				 && ($old_pay eq "P" || $old_pay eq "6" || $old_pay eq "AF" || $old_pay eq "K" || $old_pay eq "8" || $old_pay eq "AP")) {
				my $pay_exists;
				$sql=" select * from ctninfo..Airbook_pay_yd where Reservation_ID='$old_resid' ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							$pay_exists="Y";
						}
					}
				}
				if ($pay_exists eq "Y") {
					print MessageBox("������ʾ","�Բ�����Ʊ����$res_idԭĸ��ʹ������֧��,����������Ƿ��,ֻ�ɵ�������,����ʹ�������˿�ӿ����˿"); 
					exit;
				}
				
			}
			my $c_sql;	## ���ÿͻ���������	dabin@2012-12-26
			if ($cust_pay_date eq "") {
				if ($old_ticket_time eq "") {
					$c_sql = ",Send_date=getdate()";
				}
				else{
					$c_sql = ",Send_date=Ticket_time";
				}
			}
			if ($old_status eq "H" ) {	
				push(@res_h,"$res_id"); 
			}
			else{	## ����Ƿ��
				$sql = "begin transaction sql_insert \n";
				my $tcomm_tmp_id=0;
				for ($j=0;$j<$in{num};$j++) {
					my	$cb_tmp="resia_$j";		my $res_id_per=$in{$cb_tmp};
					if ($res_id eq $res_id_per) {
						my $res_tmp="res_tmp_$j";my $res_tmp_id=$in{$res_tmp};
						my $last_tmp="last_tmp_$j";my $last_tmp_id=$in{$last_tmp};
						my $ticket_tmp="ticket_tmp_$j";my $ticket_tmp_id=$in{$ticket_tmp};
						my $airdate_tmp="airdate_tmp_$j";$airdate_tmp_id=$in{$airdate_tmp};
						my $r_price="recv_account_$j";	$r_price=$in{$r_price};
						$total_use = $total_use+$r_price;
						if ($r_price != 0) {
							my $tt_old_ticket_time=$old_ticket_time;
							$tt_old_ticket_time =~ s/\.//g;
							
							##û����  liangby@2013-1-7
#							if ($Pay_version eq "1" && $old_pay eq "N" && $tt_old_ticket_time >=$Newpay_date ) {##���ʽ�ת��   liangby@2010-12-26
#							   $sql .= "  if exists(select * from ctninfo..Airbook_pay_$Top_corp where  Reservation_ID='$res_id' 
#										and Res_serial=$res_tmp_id and Last_name='$last_tmp_id' and Op_type='S' and Operate_date=convert(char(10),getdate(),102) )
#								  begin
#										update ctninfo..Airbook_pay_$Top_corp set Pay_object='1004.03.03',User_ID='$in{User_ID}'
#										where  Reservation_ID='$res_id' and Res_serial=$res_tmp_id 
#										and Last_name='$last_tmp_id' and Op_type='S' and Operate_date=convert(char(10),getdate(),102)
#								  end
#								  else
#								  begin
#									  insert into ctninfo..Airbook_pay_$Top_corp(Reservation_ID,Res_serial,Last_name,Pay_serial,Pay_object,
#											Price_total,Recv_total,Left_total,User_ID,Operate_time,Comment,Corp_ID,Op_type,
#											Ticket_time,Sales_ID,Operate_date,CID_corp,Pre_recv)
#										select '$res_id',$res_tmp_id,'$last_tmp_id',Isnull(max(Pay_serial),0)+1,'1004.03.03',
#											$r_price,0,$r_price,'$in{User_ID}',getdate(),'Ƿ���ʽ�ת��','$Corp_center','S',
#											'$ticket_tmp_id','$Corp_center',convert(char(10),getdate(),102),'$bk_corp',0
#										from ctninfo..Airbook_pay_$Top_corp 
#										where Reservation_ID='$res_id' 
#											and Res_serial=$res_tmp_id 
#											and Last_name='$last_tmp_id'
#								 end \n ";
#							}
							if ($Pay_version eq "1" && $CERT_TYPE ne "Y") {##���ѵ�ֻ��һ�ֹ���  liangby@2013-12-16
								$in{pay_method}="1004.03.03";
								#����;��Ϊ��ʱǷ��
							   $sql .=" update  ctninfo..Airbook_pay_$Top_corp set User_ID='$in{User_ID}',Pay_object='1004.03.03',
									Operate_time=getdate(),Comment='$kq_payname',Corp_ID='$Corp_ID' where Reservation_ID='$res_id' and Res_serial=$res_tmp_id and Last_name='$last_tmp_id' and Op_type ='G' 
								   and Pay_object in ('1004.01','1004.02') and Operate_date=convert(char(10),getdate(),102) and Pay_object <>'0' \n ";
							}
							$sql .= " if not exists( select * from ctninfo..Airbook_pay_$Top_corp where Reservation_ID='$res_id' and Res_serial=$res_tmp_id 
									and Last_name='$last_tmp_id' )
							   begin
							   insert into ctninfo..Airbook_pay_$Top_corp(Reservation_ID,Res_serial,Last_name,Pay_serial,Pay_object,
									Price_total,Recv_total,Left_total,User_ID,Operate_time,Comment,Corp_ID,Op_type,
									Ticket_time,Sales_ID,Operate_date,Person_num,Pay_trans,Pay_bank,CID_corp)
								select '$res_id',$res_tmp_id,'$last_tmp_id',Isnull(max(Pay_serial),0)+1,'$in{pay_method}',
									$r_price,0,$r_price,'$in{User_ID}',getdate(),'$kq_payname ����Ƿ��$in{pingzheng}','$Corp_ID','G',
									'$ticket_tmp_id','$Corp_center',convert(char(10),getdate(),102),1,'$in{pingzheng}','','$bk_corp'
								from ctninfo..Airbook_pay_$Top_corp 
								where Reservation_ID='$res_id' 
									and Res_serial=$res_tmp_id 
									and Last_name='$last_tmp_id' \n ";	
							$sql .="end\n";
							my $new_status;
							if ($old_status eq "S") {	$new_status="Book_status='H',";		}
							$sql .= "update ctninfo..Airbook_$Top_corp set $new_status Pay_method='$in{pay_method}',Pay_user='$in{User_ID}',Pay_date=convert(char(10),getdate(),102)$c_sql where Reservation_ID='$res_id' \n";
						}					
					}
				}
				$sql .="insert into ctninfo..Res_op values('$res_id','A','$in{User_ID}','0',getdate()) \n ";
				if ($Corp_center eq "TSN210" ) {##���Զ��Ҫ����Ƿ���Ҳ�޸Ļ�Ա�����������  liangby@2016-4-12
					$sql .= " update ctninfo..User_info set Last_bk_time=getdate() where User_ID='$user_id' and Corp_num='$Corp_center' and User_type='C' \n";
				}
                #print "<pre>$sql</pre>";
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
					$db->ct_execute("Commit Transaction sql_insert");
					#$db->ct_execute("Rollback Transaction sql_insert");
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT) {
							while(@row = $db->ct_fetch) {
							}
						}
					}
				}
				else{
					$db->ct_execute("Rollback Transaction sql_insert");
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT) {
							while(@row = $db->ct_fetch) {
							}
						}
					}
					print MessageBox("������ʾ","���� $res_id Ƿ�����ʧ��!");
					exit;
				}				
			}
		}
	}
	if($total_use ne ""){
		$r_num=scalar(@res_h);
		$res_h = join(",",@res_h);
		print qq!<font style='color:blue;font-size:12px;'>�ɹ�Ƿ�� $total_use</font>!;
		if ($r_num > 0) {
			print qq!<br><font style='color:red;font-size:12px;'>��ʾ: �Բ��𣬶��� $res_h ��״̬�Ѹı䣬���ܽ���Ƿ�����</font>!;
		}
	}else{
		print qq!<font style='color:red;font-size:12px;'>��ѡ�񶩵�����Ƿ��!;

	}
}

## ������Ʒ����
sub inc_account{
	$sql =" select rtrim(User_ID),First_name+Last_name,Tel,Mobile_no
	  from ctninfo..User_info_op 
	  where Corp_num='$Corp_center' and User_type in ('S','O','Y') ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$user_name{$row[0]}=$row[1];
				$user_tel{$row[0]}="�绰:$row[2] �ֻ�:$row[3]";
			}
		}
	}
	my %pay_method=&Get_pay_method("N","hash");
	my %kemu_hash = &get_kemu($Corp_center,"","hash","","");
	%pay_method=(%pay_method,%kemu_hash);
	#�տ����
	my $mo_order="desc";#Ĭ������
	#if ($in{order_name} eq "") {$in{order_name}="Ticket_date";}#Ĭ������
	if ($in{order_type} ne "asc" && $in{order_type} ne "desc") {$in{order_type}=$mo_order;}
	my $order_name=$in{order_name};
	if ($in{order_type} eq "asc") {
		$order_dir{$order_name}="��";
		$order_op{$order_name}="desc";
	}elsif($in{order_type} eq "desc"){
		$order_dir{$order_name}="��";
		$order_op{$order_name}="asc";
	}
	$backdrop{Res_ID}=qq! class="bgblue"!;
	$backdrop{Corp_ID}=qq! class="bgblue"!;
	$backdrop{left_price}=qq! class="bgblue"!;
	$backdrop{$order_name}=qq! class="bgwithe"!;
	my $over=qq! style="cursor:hand;"!;
	print qq`
	<style>.bgwithe{background:#FAFAFA; color:#FF4500;}.bgblue{color:blue;}</style>
	<script language='javascript' >
	function  inc_cash(resid){
		window.open('inc_account_do.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&History=$in{History}','PY_'+resid,'scrollbars,width=860,height=400,left=200,top=200');
	}
	function Show_book(resid){
		window.open('/cgishell/golden/admin/inc_goods/inc_view.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&History=$in{History}','V_'+resid,'scrollbars,width=540,height=320,left=200,top=200');
	}
	function show_his(resid){
		window.open('/cgishell/golden/admin/inc_goods/inc_history.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&History=$in{History}','P_'+resid,'scrollbars,width=420,height=300,left=200,top=200');
	}
	function Show_relate(resid){
		window.open('air_relate.pl\?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid,'R_'+resid,'scrollbars,width=360,height=280');
	}
	function order(order_name,order_type){
		if (order_type=='') {order_type="$mo_order";}
		document.query.order_name.value=order_name;
		document.query.order_type.value=order_type;
		document.query.submit();
	}
	</script>`;

	print qq`<script type='text/javascript' src='/admin/js/tips/tips.js'></script>
		<form method=post name=book action=''>
		<div class="airlines_list scroll_chaoc">
		<table width="100%" border="0" cellspacing="1" cellpadding="1" bgcolor="dadada"><tbody>
		<tr bgcolor="#efefef">`;
	if ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3){	
		print "<td height='30'><font color=blue>����</td>";	
	}else{
		print "<td height='30'></td>";	
	}
	print qq!
		<td height=19$over $backdrop{Res_ID} onclick="order('Res_ID','$order_op{Res_ID}');" title="������������">������$order_dir{Res_ID}</td>
		<td>��Ʒ����</td>
		<td>��Ʒ����</td>
		<td>״̬</td>
		<td>�տʽ</td>
		<td>Ԥ����</td>
		<td$over $backdrop{Corp_ID} onclick="order('Corp_ID','$order_op{Corp_ID}');" title="���ͻ�����">�ͻ�$order_dir{Corp_ID}</td>
		<td>��Ա</td>
		<td>��ϵ��</td>
		<td>����Ա</td>
		<td align=right>�ܽ��</td>
		<td align=right>���ս��</td>
		<td align=right$over $backdrop{left_price} onclick="order('left_price','$order_op{left_price}');" title="��Ӧ�ս������">Ӧ�ս��$order_dir{left_price}</td>!;
	if ($in{Op} ne "1") {
		print qq!<td align=right>ʵ�ս��</td>!;
	}
	if($in{day_type} eq "D") {
		print "<td align=center>����</td>";
	}
	print "</tr></tbody>";
	if ($in{Op} eq "") {
		$in{Op}="0";
	}

	$sql =" select a.Res_ID,a.Inc_title,a.User_ID,a.Out_total+a.Other_fee,a.Recv_total,a.Book_status,
			a.Recv_total-a.Out_total-a.Other_fee,a.Corp_ID,b.Corp_csname,a.Contract,a.Book_ID,rtrim(a.Sender),a.Pay_method,
			rtrim(a.Relate_ID),c.Inc_title
		from ctninfo..Inc_book a,ctninfo..Corp_info b,ctninfo..Inc_goods c
		where a.Corp_ID=b.Corp_ID
			and a.Inc_id *=c.Inc_id
			and c.Corp_ID ='$Corp_center'
			and a.Sales_ID='$Corp_center' 
			and b.Corp_num='$Corp_center' 
			and a.Book_status not in('W','Y') 
			and a.Order_type+''=''
			and a.Pro_id not in(11,27,28,26) \n";#fanzy@2012-6-6	���ε� ����ȷ�ϵ����������,������
	@parentGroup = split(',', $in{parent_corp});#�����ͻ�
	$size = @parentGroup;
	for($a = 0; $a < scalar(@parentGroup); $a ++ ){
		if($parentGroup[$a] ne ""){
			if ($a<$size-1) {
				$corplesql .= "'$parentGroup[$a]',";
			}else{
				$corplesql .= "'$parentGroup[$a]'";
			}
		}
	}
	if ($corplesql ne '') {
		$sql .= " and b.Parent_corp IN ($corplesql)  \n";
	}
	if ($Corp_type ne "T") {#fanzy@2012-7-17	���ε� Ԥ�����ֵ��
		##�ӱ�������Ҫ��Ӫҵ��Ҳ��������Ԥ�����ֵ��   liangby@2015-3-5
		if ($Corp_center eq "SJW121" && $Is_delivery eq "Y") {
			$sql .=" and a.Send_corp='$Corp_ID' \n";
		}else{
			$sql .=" and a.Pro_id<>12\n";
		}
		if (($Corp_center eq "KWE116" || $Corp_center eq "CTU300") && $Is_delivery eq "Y" && ($in{Corp_ID} ne "" ||
				 $in{Res_ID} ne "" )) {	## ���������ſ�����
		}
		else{
			$sql .= " and a.Send_corp ='$Corp_ID' \n";	
		}
	}
	if ($in{Order_type} == 3) {##ֻ�鿴�տ wfc@2016-03-27
		$sql .=" and a.Pro_id in(10) \n";
	}
	if ($in{Res_ID} ne "") {
		if (index($in{Res_ID},",")>-1) {##�����Ŵ�
			my @res_temp=split(",",$in{Res_ID});
			my $res_str = join ("','",@res_temp);
			$sql .=" and a.Res_ID in ('$res_str') \n";
		}
		else{
			$sql .= "and a.Res_ID='$in{Res_ID}' \n";
		}
	}
	else{
		if ($in{Corp_ID} ne "") {	$sql .=" and a.Corp_ID = '$in{Corp_ID}' \n";	}
		if ($in{userid} ne "") {	$sql .=" and a.User_ID = '$in{userid}' \n";	}
		if ($in{Guest_name} ne "") {	$sql .=" and a.Contract = '$in{Guest_name}' \n";	}
		if ($in{user_book} ne "") { $sql .= " and a.Book_ID = '$in{user_book}' \n";	}
		if ($in{Order_type} eq "3") {#�տ
			$sql .=" and a.Pro_id=10";
			if ($in{date_type} eq "C") {#��������
				$sql .=" and a.Pay_date>='$in{Depart_date}' and a.Pay_date<'$in{End_date}'";
			}elsif($in{date_type} eq "S"){#��������
				$sql .=" and a.Send_date>='$in{Depart_date}' and a.Send_date<'$in{End_date}'";
			}else{#ȷ������
				$sql .=" and a.Ticket_date>='$in{Depart_date}' and a.Ticket_date<'$in{End_date}'";
			}
		}else{
			if ($in{date_type} eq "T" || $in{date_type} eq "B" || $in{date_type} eq "") {
				if ($in{Air_type} eq "O") {##�ͻ�Ƿ��ҳ�������
					if ($Depart_date ne "") {
						$sql .= "and a.Ticket_date >='$Depart_date'  ";
					}
					if ($in{End_date} ne "") {
						$sql .=" and a.Ticket_date <'$in{End_date}' ";
					}
					$sql .=" and a.Pro_id not in (10) ";
				}else{
					$sql .= "and a.Ticket_date >='$Depart_date' 
						and a.Ticket_date <'$in{End_date}' \n";
				}
			}
			elsif($in{date_type} eq "S"){
				$sql .= "and a.S_date >='$Depart_date' 
					and a.S_date <'$in{End_date}' \n";
			}
			else{
				$sql .= "and a.Book_time >='$Depart_date' 
					and a.Book_time <'$in{End_date}' \n";
			}
		}
		if ($in{Op} eq "0") {	## δ����
			if ($in{Op_detail} eq "1") {##����Ʊδ��,����ͳ�ƹ�����   liangby@2017-8-16
				$sql .= "and a.Book_status ='S' and a.Recv_total=0  ";
			}else{
				$sql .=" and a.Book_status in ('P','S') and a.Recv_total=0 and ((a.Out_total+a.Other_fee)!=0 or ((a.Out_total+a.Other_fee)=0 and a.Pay_method='N')) \n";
			}
		}elsif ($in{Op} eq "1"){	## ������
			$sql .=" and a.Recv_total = a.Out_total+a.Other_fee \n";
		}elsif($in{Op} eq "2"){	## ������Ƿ��
			if ($in{q_type} eq "shou") {
				$sql .=" and a.Book_status in ('P','S','H')  and a.Recv_total < a.Out_total+a.Other_fee and a.Pay_method<>'N'\n";
			}elsif($in{q_type} eq "fu"){
				$sql .=" and a.Book_status in ('P','S','H')  and a.Recv_total > a.Out_total+a.Other_fee and a.Pay_method<>'N' \n";
			}else{
				if($in{Air_type} eq "O"){ ##�ӿͻ�Ƿ������ҳ��  zhangl@2011-10-21
					$sql .=" and a.Book_status in ('P','S','H') and a.Recv_total!= a.Out_total+a.Other_fee \n"
				}else{
					$sql .=" and a.Book_status in ('P','S','H') and a.Pay_method<>'N' and a.Recv_total != a.Out_total+a.Other_fee \n";
				}
			}
		}
		elsif($in{Op} eq "3"){	## �ѳ�Ʊδ��
			$sql .=" and a.Book_status ='P' \n";
		}
		if ($in{SPay_type} ne "") {
			$sql .=" and a.Pay_method ='$in{SPay_type}' \n";
		}
		if ($in{send_corp_id} ne "") {  ## ���ͻ��� hejc@2017-05-03
			$sql .=" and a.Send_corp = '$in{send_corp_id}' \n";
		}
		if($in{order_name} eq "Res_ID") {
			$sql .= "order by a.Res_ID $in{order_type} \n";
		}elsif($in{order_name} eq "Corp_ID") {
			$sql .= "order by a.Corp_ID $in{order_type} \n";
		}elsif($in{order_name} eq "left_price") {
			$sql .= "order by a.Out_total+a.Other_fee-a.Recv_total $in{order_type} \n";
		}else{
			$sql .= "order by a.Ticket_date \n";
		}
	}
	
	#print "<pre>$sql</pre>";
	my ($Out_total,$Recv_total,$Left_total,$i)=(0,0,0,0);
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row=$db->ct_fetch)	{
				my $left_price=sprintf("%.2f",$row[3]-$row[4]);
				$Pm="";
				if($left_price !=0 && $row[12] ne "N"){##�������ܼƲ���ʱ��״̬  zhangl@2011-10-21
					$b_st_str = "Ƿ������";
					$Pm="N";
				}else{
					$b_st_str=&get_book_status($row[5]);
				}
				$corpid=$row[7];
				$Out_total +=$row[3];
				$Recv_total +=$row[4];
				$Left_total +=$left_price;
				my $op=qq!<a href="javascript:inc_cash('$row[0]');" title="��������" >$row[0]</a>!;
				my $sender_str;
				my $pay_name=$pay_method{$row[12]};
				if ($row[11] ne "") {
					$sender_str="$row[11] $user_name{$row[11]} <img src='http://$G_SERVER/admin/index/images/phone.gif' style='cursor:pointer;' tipstitle='$user_name{$row[11]} $user_tel{$row[11]}' border=0 align=absmiddle>";
				}
				$a_dis = "";
				if ($left_price ==0) {
					$a_dis="disabled";
				}
				print qq`<tr class="odd" onmouseout="this.style.background='#ffffff'" onmouseover="this.style.background='#fef6d5'">`;
				if ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3){##������������ hecf 2014/8/8
					print qq!<td width=30>
						<input $a_dis type="checkbox" name=cb_$i value="$row[0]" onclick="statistics();" class="radio_publish">
						<input type=hidden name=Reservation_ID_$i value="$row[0]" /><input type=hidden name=old_left_total_$i value="$left_price" />
						<input type=hidden name=old_recv_total_$i value="$left_price" />
						</td>!;
				}else{	print "<td></td>";	}

				print qq!<td height=20>$op</td>
					<td>$row[14]</td>
					<td><a href="javascript:Show_book('$row[0]');" >$row[1]</a></td>
					<td><a href="javascript:show_his('$row[0]');" title="������¼">$b_st_str <input type=hidden id=pm_$i value="$Pm" /></a></td>
					<td>$pay_name</td>
					<td title='$user_name{$row[10]}'>$row[10]</td>
					<td>$row[7] $row[8]</td>
					<td>$row[2]</td>
					<td>$row[9]</td>
					<td>$sender_str&nbsp;</td>
					<td align=right >$row[3]</td>
					<td align=right >$row[4]</td>
					<td align=right >$left_price</td>!;
				if ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3) {
					print qq!<td align=right><input type=text name="recv_total_$i" value="$left_price" class="input_txt" style='color:blue;width:45px;' onblur="statistics();"/></td>!;
				}
					print qq!
					</tr>!;
				$i++;
			}
		}
	}

	$Out_total=sprintf("%.2f",$Out_total);
	$Recv_total=sprintf("%.2f",$Recv_total);
	$Left_total=sprintf("%.2f",$Left_total);

	print qq!<tr align=right bgcolor="#ffffff"><td colspan=2 align=left ><label><input type="checkbox" name="cb" onclick="ck_all();" class="radio_publish">ѡ��ȫ��</label></td>
	<td colspan=9 height=21>�ϼƣ�</td>
	<td>$Out_total</td>
	<td><font color=blue>$Recv_total</font></td>
	<td>$Left_total</td><td>&nbsp;</td>
	</tr></table></div>
	<div class="clear"></div>!;

	if ($i > 0 &&($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3)){#������������������� hecf 2014/8/8
		my @tmp_array_list = ();
		##ԭ�տʽ����Ϣ  ,��ʾ������ϸʱ�õ���ǰ��������ʽ
		$sql = "select rtrim(Pay_method),Pay_name,Is_netpay,Is_show,Is_payed,Corp_ID,Pay_pic from ctninfo..d_paymethod 
			where  Corp_ID in ('SKYECH','$Corp_center') 
			order by Order_seq,Is_netpay ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
					if ($Pay_version ne "1") {
						if ($row[3] eq "Y" && $row[2] eq "N" && $row[4] eq "Y") {
							push(@array_list, {Corp_ID   => "$row[5]",
								Type_ID => "$row[0]",
								Type_name  => "$row[1]",
								Pic => "$row[6]",
								Pid => "$row[0]",
								Parent => "",
							});
						}
					}
				}
			}
		}
		if ($Pay_version eq "1") {
			##��ȡ��ƿ�Ŀ����Ϣ��ϣ��  liangby@2010-12-11
			%kemu_hash = &get_kemu($Corp_center,"","hash2","","","","assist","N");
			## ��ƿ�Ŀ����
			@array_list = &get_kemu($Corp_center,"","array",1,"Y");
		}
		## �����Ŀ�б�
		my $ass_ids;
		for (my $i = 0; $i < scalar(@array_list); $i++) {
			if ($array_list[$i]{Type_ID} eq $array_list[$i]{Pid}) {		$array_list[$i]{Pid} = '';	}
			my $listitem = qq`['$array_list[$i]{Corp_ID}', '$array_list[$i]{Type_ID}', '$array_list[$i]{Type_name}', '$array_list[$i]{Pid}','0']`;
			push(@tmp_array_list, $listitem);
			if ($array_list[$i]{Pid} ne "") {
				$ass_ids .= "','$array_list[$i]{Pid}";
			}
		}
		## ���������б�
		if ($ass_ids ne "" && $Pay_version == 1) {
			my @bank=&get_kemu($Corp_center,"","array","1","Y","N","assist");	
			for (my $i = 0; $i < scalar(@bank); $i++) {
				my $listitem = qq`['$bank[$i]{Corp_ID}', '$bank[$i]{Type_ID}', '$bank[$i]{Type_name}', '$bank[$i]{Parent}','1']`;
				push(@tmp_array_list, $listitem);
				$bank_name{$bank[$i]{Type_ID}}=$bank[$i]{Type_name};
			}
		}
		my $Operate_date_js=(($Function_ACL{CWSY}&(1<<0)) != 0)?qq` onfocus="WdatePicker({dateFmt:'yyyy.MM.dd',skin:'whyGreen',maxDate:'$today'});"`:"";
		print qq`
		<script defer="defer" language="text/javascript" type="text/javascript" src="/admin/gate/js/My97DatePicker/WdatePicker.js"></script>
		<div class="operating" >
		<div class="operating_button">
		<table width="100%" border="0" cellspacing="0" cellpadding="6">
		<tbody>
		<tr>
			<td>
				<table width="99%" border="0" cellspacing="0" cellpadding="6">
					<tbody>
						<tr>
							<td width="90">
								<label>
									<input type=radio id='all_type_S' name='all_type' value='S' onclick='cal_recv();' checked class='radio_publish'>��������
								</label>
							</td>
							<td>`;
		$show_qk_radio="none";
		if ($in{Op} ne 2) {
			$show_qk_radio="block";
		}
		print qq`
			<label style="display:$show_qk_radio">
				<input type=radio id='all_type_Q' name='all_type' value='Q' onclick='cal_debt();' class='radio_publish'>����Ƿ��
			</label>`;
		print qq`
							</td>
							
							<td>
								�������ڣ�<input name="Operate_date" id="Operate_date" type="text" class=grayline style='width:70px;' maxlength="10" value="$today" $Operate_date_js readonly="readonly"/>
							</td>
							<td>
								<a class="red" id="ss">&nbsp;ѡ�ж�����ʵ��&nbsp;<input name="Rec_tol" type="text" class="input_txt input_txt70" style='color:blue' value="$Recv_total" readonly="" /></a>
							</td>
							<td>
								<a class="" id="wjs">δ���㣺<input name="Left_total" type="text" class="input_txt input_txt70" style='color:red' value="$Left_total" readonly="" /><input type=hidden name=Total value='$Left_total'></a>
							</td>
							<td>
								<a id='Left_tol_id' style='display:none'>Ƿ���ܼƣ�<input  name="Left_tol" type="text" class="input_txt input_txt70" style='color:red' value="0" readonly=""/></a>
							</td>
							
						</tr>
						<tr>
							<td width="180">
								<label id="More_pay_mod"><nobr>
									<input name="" type="button" class="upload diaod_button" value="���֧����ʽ" onclick="More_pay('add');"/>&nbsp;&nbsp;
									<input name="" type="button" class="save_ad diaod_button" value="����֧����ʽ" onclick="More_pay('del');"/></nobr>
								</label>
							</td>
							<td colspan=3 align=right >
								&nbsp;&nbsp;<input name="bt_ok" id="bt_ok" type="button" class="again button_sizegy " onclick='button_onclick()' value="ȷ���ύ" />
								<input name="" type="reset" class="again button_sizegy " value="��  ��" />
							</td>
							<td>&nbsp;</td>
						</tr>
					</tbody>
				</table>
			</td>
		</tr>`;
		my $paymaxnum=30;#�տʽ�������3��
		for (my $p=0;$p<$paymaxnum ;$p++) {
			my $display=($p==0)?"":"display:none;";
			my $pp=($p==0)?"":"_$p";
			print qq`
			<tr id="paymore$pp" style="$display">
				<td>
					<table border=0 width=100% cellspacing=0 cellpadding=1 border=0 bgcolor=efefef style="border-bottom-color:#ddd;border-bottom-width:1px;border-bottom-style:dashed;">
						<tr width=80%>
							<td height=20>
								<label>�տʽ��<select id="list1$pp" name="Pay_type$pp" class="input_txt_select input_txtgy" style='width:130pt;' onchange="if('$Pay_version'=='1'){changelist('list1', 'list2','$p');};load_credit_payment('$p');">$pay_list</select></label>
								<label>ƾ ֤ �ţ�<input type=text value='' id='pingzheng$pp' name='pingzheng$pp' style='width:100px;position:relative;z-index:10;' class="input_txt input_txt70">
										<select id='pingzhenglist$pp' name='pingzhenglist$pp' class="input_txt_select input_txtgy" style="height:26px;position:absolute;margin-top:1px;margin-left:-105px;width:120px;z-index:2;" onchange="change_cmt('pingzhenglist$pp', 'pingzheng$pp','Pay_balance$pp')" onclick="if(this.options.length==1){change_cmt('pingzhenglist$pp', 'pingzheng$pp','Pay_balance$pp');}"></select>&nbsp;&nbsp;&nbsp;
								</label>
							</td>
							<td>		
								<label id="shishou">ʵ�գ�<input type=text id="Pay_Rec_tol$pp" name="Pay_Rec_tol$pp" class="input_txt input_txt70" style='color:blue' value=0></label>
							</td>
							<td>
								<label>��<span id="Pay_balance$pp"></span></label>
							</td>
						</tr>
						<tr>
							<td height=20>
								<label id='list2_lb$pp'>������Ŀ��<select id="list2$pp" name='Pay_type2$pp' class="input_txt_select input_txtgy" style='width:130pt;' onchange="load_credit_payment('$p');"></select></label>
								<label id='list3$pp'>���ײο��ţ�<input type="text" id="ReferNo$pp" name="ReferNo$pp" maxlength=16 class="input_txt input_txt70" value="">
										�����У�<input type="text" id="BankName$pp" name="BankName$pp" maxlength=8 class="input_txt input_txt70" value="">
										�������ڣ�<input type=text id="ReOp_date$pp" name="ReOp_date$pp" class="input_txt input_txt70" readonly maxlength=10 value='' onclick="event.cancelBubble=true;ShowCalendar(document.book.ReOp_date$pp,document.book.ReOp_date$pp,null,0,330)">
										���ź�4λ��<input type="text" id="BankCardNo$pp" name="BankCardNo$pp" class="input_txt input_txt70" maxlength=4 value="">
								</label>
							</td>
						</tr>
						<tr>
							<td>		
								��ע:
								<textarea name="Comment$pp" maxlength=128 cols="" rows="" class="input_txt " style=" width:100%;height:50px;"></textarea>
							</td>
						</tr>
					</table>
				</td>
			</tr>`;
		}
		print qq`
		<input type='hidden' name='pay_method_num' id='pay_method_num' value='1'/>
		<input type='hidden' name='pay_method_maxnum' id='pay_method_maxnum' value='$paymaxnum'/>
		</tbody></table></div>`;
		print qq`
		<script language='javascript'>
			function cal_debt(){
				count_Left_tol();
				More_pay('');
				document.getElementById("ss").style.display = "none";
				document.getElementById("wjs").style.display = "none";
				document.getElementById("shishou").style.display = "none";
				document.getElementById("More_pay_mod").style.display = "none";
				document.getElementById("Left_tol_id").style.display = "block";
			}
			function count_Left_tol(){
				if (document.getElementById("all_type_Q").checked == true) {
					for (var j=0; j < document.book.t_num.value; j++){
						var ab="pm_"+j;
						if(eval("document.book.cb_"+j).checked&&document.getElementById(ab).value=="N"){
							var book_id=eval("document.book.cb_"+j).value;
							alert(book_id+"������ΪǷ��״̬���޷��ظ�Ƿ��");
							eval("document.book.cb_"+j).checked=false;
						}
					}
				}
				var account = 0;
				for (var j=0; j < document.book.t_num.value; j++){	
					if(eval("document.book.cb_"+j).checked){
						account += parseFloat(eval("document.book.recv_total_"+j).value);
					}
				}
				document.book.Left_tol.value=account;
			}
			function cal_recv(){
				document.getElementById("ss").style.display = "block";
				document.getElementById("wjs").style.display = "block";
				document.getElementById("shishou").style.display = "block";
				document.getElementById("More_pay_mod").style.display = "block";
				document.getElementById("Left_tol_id").style.display = "none";
			}
			function ck_all(){
			if ( document.book.t_num.value == 0 ) return; 
				if (document.book.cb.checked) {
					for (var j=0; j < document.book.t_num.value; j++){	eval("document.book.cb_"+j).checked = true;   }
				}else{
					for (var j=0; j < document.book.t_num.value; j++){	eval("document.book.cb_"+j).checked = false;	}
				}
				statistics();
				count_Left_tol();
			}
			function statistics(){
				var Paid = 0;//ʵ��
				var Settlement =0;//δ����
				for (var j=0; j < document.book.t_num.value; j++){	
					if(eval("document.book.cb_"+j).checked){
						Paid += parseFloat(eval("document.book.recv_total_"+j).value);
					}
					Settlement += parseFloat(eval("document.book.old_recv_total_"+j).value);
					
				}
				Settlement=Settlement-Paid;
				document.book.Rec_tol.value=Round(Paid,2);
				document.book.Left_total.value=Round(Settlement,2);
				if (document.book.pay_method_num.value=='1') {
					document.book.Pay_Rec_tol.value = document.book.Rec_tol.value;
				}
				count_Left_tol();
				
			}
			function button_onclick(){
				var num=parseInt(document.getElementById('pay_method_num').value,10);
				var Pay_Rec_tol=0;
				var Pay_Recv_Mark='';
				for (var p=0;p<num ;p++) {
					var pp='_'+p;
					if (p=='0') {
						pp='';
					}
					var Pay_Rec_tol_p=document.getElementById("Pay_Rec_tol"+pp);
					if(isNaN(Pay_Rec_tol_p.value)){ 
						alert('�տʽ��ʵ�ս����������֣�');
						Pay_Rec_tol_p.focus(); 
						return false; 
					}
					var Pay_Recv_Marks='';
					if (parseInt(Pay_Rec_tol_p.value,10)<0) {
						Pay_Recv_Marks='-1';
					}else{
						Pay_Recv_Marks='1';
					}
					if (Pay_Recv_Mark=='') {
						Pay_Recv_Mark=Pay_Recv_Marks;
					}
					if (Pay_Recv_Mark!=Pay_Recv_Marks) {
						alert('�տʽ��ʵ�ս����ͳһ������');
						Pay_Rec_tol_p.focus(); 
						return false; 
					}
					Pay_Rec_tol=Pay_Rec_tol+Round(Pay_Rec_tol_p.value,2);
				}
				Pay_Rec_tol=Round(Pay_Rec_tol,2);
				if (Pay_Rec_tol!=document.book.Rec_tol.value) {
					alert('�տʽ��ʵ�ս��֮��'+Pay_Rec_tol+'������ѡ�ж�������ʵ�պϼ�'+document.book.Rec_tol.value+'��');
					document.getElementById('Pay_Rec_tol').focus(); 
					return false; 
				}
				var rst ;
				var is_sxk=document.getElementById("is_sxk").value;
				if(is_sxk == "Y"){		//������ͻ��Ӹ�����
					rst=confirm("�ÿͻ�Ϊ������ͻ�����ȷ���տʽ�Ƿ���ȷ?");
					if(rst==false){
						return;
					}
				}
				var need_count=document.getElementById("need_count").value;
				if(need_count != '' &&  need_count != Pay_Rec_tol){		//�˵������ʵ�ս��ȼӸ�����
					rst=confirm("�˵����������ʵ�ս��ȣ���ȷ���Ƿ��������?");
					if(rst==false){
						return;
					}
				}
				document.getElementById("bt_ok").disabled=true;
				document.book.submit();
			}
			function Round(a_Num , a_Bit)  {
				return( Math.round(a_Num * Math.pow (10 , a_Bit)) / Math.pow(10 , a_Bit))  ;
			}
		</script>`;
		## ������Ŀ����
		my $array_list = join(",\n", @tmp_array_list);
		##���Ҫ�޸ĸ�JS,��ɰ���տʽ   liangby@2010-12-23
		print qq`
		<script type="text/javascript">
			var payhash=[];
			var datalist = [$array_list];
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
					document.book.Pay_Rec_tol.value = document.book.Rec_tol.value;
				}
			}
			function createlist(list, pid,payid) {
				var ppayid='_'+payid;
				if (payid=='0') {
					ppayid='';
				}
				removeAll(list);
				if (list.id=="list2"+ppayid) {
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
					if (pid == '' && datalist[i][4] != '0')	{	// ���ʽ
						continue;
					}
					if (array_exists(exists_value, datalist[i][1]))	// �����ظ��������б�
					{
						continue;
					}
					list[list.options.length] = new Option(datalist[i][2], datalist[i][1]);
					exists_value.push(datalist[i][1]);	// д����������������ж��ظ�
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
					if (list.id=="list2"+ppayid) {
						list.style.display ='none';
						document.getElementById("list2_lb"+ppayid).style.display='none';
					}
				}
				if (pid=='1003.01.01' || pid=='1003.01.02') {//POS�����������п��ŵ�fanzy2012-6-27
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
			var removeAll = function(obj){
				obj.options.length = 0;
			}
			//�������Ԫ���Ƿ����
			function array_exists(arr, item){
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
			for (var i=0;i<parseInt(document.getElementById("pay_method_maxnum").value,10) ;i++) {
				changelist('', 'list1',i);
				changelist("list1","list2",i);
			}
		</script>
		`;
	}
	print qq!
	<input type=hidden name=User_ID value="$in{User_ID}" />
	<input type=hidden name=Serial_no value="$in{Serial_no}" />
	<input type=hidden name=Order_type value="$in{Order_type}" />
	<input type=hidden name=Depart_date value="$Depart_date" />
	<input type=hidden name=End_date value="$End_date" />
	<input type=hidden name=Op value="$in{Op}" />
	<input type=hidden name=Do_act value="W" />
	<input type=hidden name=Corp_ID value="$in{Corp_ID}" />
	<input type=hidden name=user_book value="$in{user_book}" />
	<input type=hidden name=Start value="1" />
	<input type=hidden name=air_type value="$in{air_type}" />
	<input type=hidden name=Sender value="$in{Sender}" />
	<input type=hidden name=History value="$in{History}" />
	<input type=hidden name=pay_obj value="$in{pay_obj}" />
	<input type=hidden name=Send_corp value="$in{Send_corp}" />
	<input type=hidden name=t_num value=$i />
	<input type=hidden name=Remark value="������������" />
	<input type=hidden name=is_sxk id=is_sxk value=''>
	<input type=hidden name=need_count id=need_count value='$in{need_count}'>
	</form>!;
	$pay_ment_corp=$in{Corp_ID};
	if ($pay_ment_corp eq "") {
		$pay_ment_corp=$corpid;
	}
	if ($pay_ment_corp ne $Corp_center && $in{Corp_ID} ne "") {##��ȡ���������   liangby@2015-6-11
		print qq`
		<div class="wrapper" id="auto_process"></div>
			<div id="payment_show" style="background:#f4f4f4; border-top: #ff6600 solid 1px;width:550px;height:200px;overflow:auto;overflow-x:hidden;display:none;" ></div>
		`;
		print qq`<script language=javascript>
			function get_credit_payment(){
				document.getElementById('auto_process').innerHTML='���ڻ�ȡ��������Ϣ�����Ժ򡭡���';
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
									html_str="<br /><table  border=1 bordercolor=808080 width=500 bordercolordark=FFFFFF cellpadding=0 cellspacing=0  ><tr><td colspan=4>�ͻ�(<b>$pay_ment_corp</b>)�����������ϸ</td></tr><tr bgcolor=f2f2f2 height=30 ><td>�����Ŀ</td><td>���������Ŀ</td><td>ƾ֤��</td><td>���</td></tr>"+html_str+"</table>";
									document.getElementById("payment_show").style.display="";
									document.getElementById("is_sxk").value="Y";
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
							document.getElementById('auto_process').innerHTML = '�����������ʾ��'+data['message']+" <input type='button' id='ticketing_rest' value='���²�ѯ������' title='���²�ѯ������' class='btn30' onmouseover=\\"this.className='btn31'\\" onmouseout=\\"this.className='btn30'\\" onclick=\\"get_credit_payment();\\" />";
						}
					},
					error: function(XMLHttpRequest, textStatus, errorThrown){
						var textStatus_str=textStatus;
						if (textStatus=="timeout") {
							textStatus_str="���糬ʱ,���Ժ�����";
						}else if (textStatus=="error") {
							textStatus_str="��̨����������";
						}
						document.getElementById('auto_process').innerHTML = '�����������ʾ��'+textStatus_str+" <input type='button' id='ticketing_rest' value='���²�ѯ������' title='���²�ѯ������' class='btn30' onmouseover=\\"this.className='btn31'\\" onmouseout=\\"this.className='btn30'\\" onclick=\\"get_credit_payment();\\" />";;
						
						
					}
				});
				
			}
			get_credit_payment();
			</script>`;
	}
}

## ��ȡ�ͻ������ı����б� dingwz@2014-06-12
sub inc_insure_list{
    my $where = " from ctninfo..Inc_goods a,
		ctninfo..d_inc_pro b
		where a.Corp_ID='$Corp_center' 
			and a.Pro_id=b.Pro_id and b.Corp_ID in ('SKYECH','$Corp_center') and b.Status='Y'
			and ((a.Start_date <= getdate() and a.End_date >getdate()) or a.Pro_id=10 ) and a.Status ='Y' and (a.Total_num=0 or a.Total_num=null or (a.Total_num>0 and a.Total_num-a.Sales_num>0)) and a.Use_obj like '%0%' \n";
	##��ȡ��Ʒ
	my $inc_pro_list="";
	my $sql =" select a.Inc_id,a.Inc_title,a.Total_num,a.Sales_num,a.Out_price,a.Reward_rate \n";
	$sql .=$where;
	$sql .=" and a.Pro_id = 6 \n";
	$sql .=" order by a.Inc_title ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$row[3]=int($row[3]);
				my $left_num=$row[2]-$row[3];
				my $class = "class=none";
				if ($left_num <1 && $row[2] > 0) {
				 	next;
				}
				$inc_pro_list .= qq!<option data='$row[4]' value='$row[0]'>$row[1]--�۸�$row[4]Ԫ</option>!;
			}
		}
	}
	return $inc_pro_list;
}

## �����޸ı������� dingwz@2014-06-12
sub inc_insure_book_resok{
    local($order_id_str,$user_id,$ic_id,$pay_type,$buy_type,$trade_no,$pay_bank)=@_;
	if($order_id_str eq ""){
	    return "<INFO><RESULT>ERROR</RESULT><ERROR>��ѡ�񶩵�</ERROR></INFO>";
	}
	## ����������֤������
	my $insure_num=0;
	my %inc_book_remark_hash=();
	my $inc_book_remark="";
	my $sql_inc_book_detail="";
	my $serialno = 0;
	my $serial = 0;
	my $old_recv_total2=0;
	my $sql_detail = "select a.First_name,a.Last_name,a.Card_ID,a.Recv_price from ctninfo..Airbook_detail_$Top_corp a where a.Reservation_ID = '$order_id_str' order by a.Res_serial,a.Last_name " ;
	$db->ct_execute($sql_detail);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
		    while(@row = $db->ct_fetch)	{
				$old_recv_total2 +=$row[3];
			    my $i_insure_num = $in{"inc_insure_num_".$order_id_str."_".$serial};
				my $i_remark = $in{"inc_insure_remark_".$order_id_str."_".$serial};
			    if($i_insure_num !=0){
				    $insure_num += $i_insure_num;
				    $sql_inc_book_detail .= " INSERT INTO ctninfo..Inc_book_detail(Res_ID, Serial_no, Sales_ID, Cust_name, Card_ID, Status,Print_no,PBook_num)
							VALUES(\@Res_no, $serialno, '$Corp_center', '$row[0]', '$row[2]', '0','',$i_insure_num)\n";
					if(!exists $inc_book_remark_hash{$i_remark}){
					    if($inc_book_remark eq ""){
						    $inc_book_remark .= $i_remark;
						}else{
						    $inc_book_remark .= "#$i_remark";
						}
						$inc_book_remark_hash{$i_remark}="";
					}
					$serialno++;
				}
				$serial++;
			}
		}
	}
	if($insure_num == 0){
	    return "<INFO><RESULT>SUCCESS</RESULT><SQL></SQL><PRICE>0</PRICE></INFO>";
	}
	if($old_recv_total2 != 0){#ֻ�е��ѳ�Ʊδ�����Ķ��������޸ı�������   liangby@2015-9-25
		 return "<INFO><RESULT>SUCCESS</RESULT><SQL></SQL><PRICE>0</PRICE></INFO>";
	}
	## =======================================
    ##��ȡ��ǰ��ʱ��
    my$today = &cctime(time);
    my($week,$month,$day,$time,$year)=split(" ",$today);
    if($day<10){$day="0".$day;}
    $today=$year.".".$month."."."$day";
	my $sql="";
	if ($ic_id ne "") {
		$sql = " select Pro_id,Inc_title,In_price,Out_price,convert(char(10),Start_date,102),convert(char(10),End_date,102),Status,Use_obj,
		   Total_num,Sales_num,Remark,Sp_corp,Tag_str,Discount,Isnull(Other_fee,0),Isnull(Book_comm,0)
		  from ctninfo..Inc_goods where Corp_ID='$Corp_center' and Inc_id=$ic_id ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					($old_pro_id,$old_inc_title,$old_in_price,$old_out_price,$old_sdate,$old_edate,$old_status,$old_use_obj,$old_total_num,$old_sales_num,
						$old_remark,$old_sp_corp,$good_tag_str,$old_dis,$old_other_fee,$book_comm)=@row;
				}
			}
		}
		if ($old_pro_id eq "") {
			return "<INFO><RESULT>ERROR</RESULT><ERROR>��ѡ���Ʒ</ERROR></INFO>";
		}
	}else{
		return "<INFO><RESULT>ERROR</RESULT><ERROR>��ѡ���Ʒ</ERROR></INFO>";
	}
	
	if($buy_type == 1){##���ͱ���
	    $old_out_price=0;
		$old_other_fee=0;
	}
	$out_total=$old_out_price*$insure_num;
    $in_total=$old_in_price*$insure_num;
    $other_fee_total=$old_other_fee*$insure_num;
	
		$sql = "declare \@Res_no varchar(15) ";
		## �޸�ָ���������ĵı���ȵĶ������
	    $sql .= qq! if not exists(select * from ctninfo..Inc_ResLimit where Agent_ID='$Corp_center' and Year='$year') 
		 BEGIN
			  insert into ctninfo..Inc_ResLimit(Agent_ID,Year,Number) values('$Corp_center','$year',0) 
		 END
		 Update ctninfo..Inc_ResLimit set Number=Number+1 where Agent_ID='$Corp_center' and Year='$year' \n!;
	    ## ���ɸô������ڱ���ȵĶ������
	    my $resid="3".substr($year,3,1);
	    $sql .= qq!select \@Res_no='$resid'+rtrim(b.Corp_CID)+
		stuff('000000',7-char_length(rtrim(convert(char(6),Number))),char_length(rtrim(convert(char(6),Number))),rtrim(convert(char(6),Number)))
		from ctninfo..Inc_ResLimit a,ctninfo..Corp_extra b
		Where a.Agent_ID=b.Corp_ID and a.Year='$year' and a.Agent_ID='$Corp_center'!;

	    my $relate_id = $order_id_str."R";
		$sql .= " update ctninfo..Airbook_$Top_corp set Relate_ID='$relate_id' where Reservation_ID='$order_id_str' \n";
		$sql .= "if not exists(select Relate_ID from ctninfo..Res_relate where Res_ID='$relate_id' and Relate_ID='$order_id_str')
			insert into ctninfo..Res_relate (Res_ID,Relate_ID,Res_type,Comment) values('$relate_id','$order_id_str','A','$inc_book_remark') \n";
		$sql .= "insert into ctninfo..Res_relate (Res_ID,Relate_ID,Res_type,Comment) values('$relate_id',\@Res_no,'G','$inc_book_remark') \n";
		my $default_send_corp = $Corp_center;
	    if($Corp_center eq "CZZ259"){ ##����Ҫ��������Ʒ�����ͻ���Ĭ��Ϊ��SHIQVS
		    $default_send_corp="SHIQVS";
	    }
		$sql .=" insert into ctninfo..Inc_book(Res_ID,Corp_ID,Book_corp,Agent_ID,Send_corp,Sales_ID,Inc_title,Inc_id,Pro_id,
		In_price,Out_price,Pro_num,Out_total,In_total,Recv_total,Contract,Tel,User_ID,Book_ID,Book_time,Pay_method,Is_op,
		Book_status,Other_fee,User_rmk,Delivery,S_date,S_time,Address,Remark,Sp_corp,Relate_ID,Effect_date,Tag_str,Book_comm,Air_resid,Ticket_by,Ticket_date,Sender) 
		select \@Res_no,Corp_ID,Book_corp,Agent_ID,Send_corp,Sales_ID,'$old_inc_title',$ic_id,$old_pro_id,
		$old_in_price,$old_out_price,$insure_num,$out_total,$in_total,0,Contact,Userbp,'$user_id',Book_ID,convert(char(10),Book_time,102),'N','N',
		'W',$other_fee_total,'','Y',convert(char(10),Send_date,102),convert(char(10),Send_stime,102),'','$inc_book_remark','$old_sp_corp','$relate_id','','',$insure_num,'$order_id_str',Ticket_by,convert(char(10),Ticket_time,102),Sender_ID
        from ctninfo..Airbook_$Top_corp where Sales_ID='$Corp_center' and Reservation_ID='$order_id_str'	\n" ;
	    $sql .=" insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) values(\@Res_no,'G','$in{User_ID}','B',getdate())\n";
		## ����������֤������
		$sql .= $sql_inc_book_detail;
		
		#$sql .=" select \@Res_no ";
		##�Զ�����
		$sql .=" update ctninfo..Inc_book set Recv_total=Recv_total+$out_total,Pay_method='$pay_type',Pay_user='$in{User_ID}',Pay_date=convert(char(10),getdate(),102),Book_status='H' where Res_ID=\@Res_no ";
		$sql .=" declare \@p_serial tinyint \n
					 select \@p_serial =max(Pay_serial)+1 from ctninfo..Inc_book_pay where Res_ID=\@Res_no 
		             select \@p_serial =isnull(\@p_serial,0)";
		my $left_price=0;
		$sql .=" insert into ctninfo..Inc_book_pay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,Pay_bank,CID_corp)
			values(\@Res_no,\@p_serial,'$pay_type',$out_total,$out_total,$left_price,'$in{User_ID}',getdate(),convert(char(10),getdate(),102),
				'������Ʊ�����Զ�����','$trade_no','$Corp_center','$Corp_ID','$pay_bank','$bk_corp')  ";
		$t_recv_total=$out_total;
		##���ֵֿ�
		my %m_type = &get_dict($Corp_center,1,"","hash");
        my $usertype = &get_mcard_type($user_id);
		if ($t_recv_total !=0  && $pay_type eq "4003.01.04"
			&& grep {$_ eq $usertype} keys %m_type) {##���ֵֿ�    liangby@2012-10-23
			$tt_usertype=$usertype;
			if ($usertype eq "N") {
				$tt_usertype="C";
			}
			my $sql_tt="select Reward_rate,right(convert(char(10),getdate(),102),8) from ctninfo..Reward_rate where Corp_ID='$Corp_center' and Product_type='R' and User_type='$tt_usertype' ";
			
			$db->ct_execute($sql_tt);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$reward_dk=$row[0];    ##��ֻ�һԪ
						$Apply_ID=$row[1];
						$Apply_ID =~ s/\.//g;
					}
				}
			}
			if ($reward_dk eq "" || $reward_dk==0) {
			    return "<INFO><RESULT>ERROR</RESULT><ERROR>�Բ���,�û�Ա������δά�����ֵֿ����ѽ�����,���ڻ��ֹ�����ά��</ERROR></INFO>";
			}
			
			##����Ҫ����
			my $need_reward=sprintf("%0.f",$t_recv_total*$reward_dk);
			##�ĴӼ�¼��ʵʱ��ȡ�ܻ��ֺ����û���    liangby@2014-6-26
			my $Total_reward=0;
			$sql_tt =" select isnull(sum(Reward),0) from ctninfo..Member_reward where User_ID='$user_id' and Corp_num='$Corp_center' ";
			$db->ct_execute($sql_tt);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$Total_reward=$row[0];
					}
				}
			}
			my $Pay_reward=0;
			$sql_tt=" select isnull(sum(Gift_num*Need_reward),0) from ctninfo..Gift_apply where Corp_num='$Corp_center' and User_ID='$user_id' and De_status <>'C' ";
			$db->ct_execute($sql_tt);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$Pay_reward=$row[0];
					}
				}
			}
			$u_left=$Total_reward-$Pay_reward;
			if ($u_left <$need_reward) {
				if ($Corp_center eq "022000" && $Corp_center eq "hx001") {##��Ѷ���ܿ��Եֿ۸����֣��ź�Ҫ��   liangby@2012-10-25
				}else{
				    return "<INFO><RESULT>ERROR</RESULT><ERROR>�Բ���,�û�Աʣ����ֲ���,�������$need_reward,ʣ�����$u_left</ERROR></INFO>";
				}
			}
			$sql .= " declare \@Apply_ID_Inc integer 
						select \@Apply_ID_Inc= max(convert(integer,Apply_ID))+1 from ctninfo..Gift_apply where Apply_ID like '$Apply_ID%'
						if \@Apply_ID_Inc=null select \@Apply_ID_Inc= $Apply_ID * 1000
						INSERT INTO ctninfo..Gift_apply (Corp_num,Corp_ID,User_ID,Apply_ID,Gift_ID,
								Gift_name,Gift_num,Need_reward,Apply_date,Delivery_method,De_person,
								De_address,De_zip,De_tel,De_email,De_status,Comment,Apply_by,Apply_time,Gift_no,APrice,Confirm_by,Confirm_time)
						VALUES ('$Corp_center','$Corp_ID','$user_id',convert(varchar(9),\@Apply_ID_Inc),-1,
								'������Ʒ�������ֵֿ�$t_recv_totalԪ,�ֿ�ǰʣ�����$u_left',1,$need_reward,getdate(),'Q','',
								'','','','','Y','������Ʒ�������ֵֿ�$t_recv_totalԪ,�ֿ�ǰʣ�����$u_left','$in{User_ID}',getdate(),\@Res_no,$t_recv_total,'$in{User_ID}',getdate()) \n";
			##ͬ���Ѷһ�����  liangby@2014-5-14
			$sql .= " update ctninfo..User_info set Pay_reward=(select isnull(sum(Gift_num*Need_reward),0) from ctninfo..Gift_apply where Corp_num='$Corp_center' and User_ID='$user_id' and De_status <>'C' ) where Corp_num='$Corp_center' and User_ID='$user_id' \n";
		}
		$sql .=" insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) 
				values(\@Res_no,'G','$in{User_ID}','H',getdate()) ";
		## ��ԱԤ���������Ƿ���֣����޸������������	
		$sql .= "update ctninfo..User_info set Last_bk_time=getdate() where User_ID='$user_id' and Corp_num='$Corp_center' \n";	
	return "<INFO><RESULT>SUCCESS</RESULT><SQL>$sql</SQL><PRICE>$out_total</PRICE></INFO>";
}
## ������Ʒ����Ƿ�� hejc@2017-05-16
sub inc_account_debt {
	my $must_pay_amount;
	$sql =" select Res_ID,Book_status,Out_total+Isnull(Other_fee,0),Recv_total,User_ID, 
		Pay_method,Inc_title,Inc_id,Corp_ID,Isnull(Other_fee,0),Old_resid,Tkt_status,Pro_id,Ticket_date,Account_period
		from ctninfo..Inc_book where Res_ID='$res_id'
		and Sales_ID='$Corp_center' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row=$db->ct_fetch)	{
				($old_id,$old_status,$Out_total,$old_recv_total,$user_id,$old_pay,$pro_title,$inc_id,$bk_corp,$old_other_fee,$old_resid,$Is_refund,$old_pro_id,$ticket_time,$old_account_period)=@row;
				if ($Is_refund eq "") {
					$Is_refund="0";
				}
				$must_pay_amount=sprintf("%.2f",$Out_total-$old_recv_total);
			}
		}
	}
	if ($old_id eq "") {
	   print MessageBox("������ʾ","����������");
	   exit;
	}
	if ($old_pay ne "N") {
	   print MessageBox("������ʾ","����:$old_id �Ѵ���Ƿ��״̬");
	   exit;
	}
	$left_total=sprintf("%.2f",$must_pay_amount);
	if ($old_status eq "S" || ($good_tag_str=~/B/ && $old_status eq "P") ) {
		$sql_status=",Book_status='H'";
	}
	$sql="
		delete from ctninfo..Inc_book_pay 
		where Res_ID='$res_id' and Op_type in ('G','S') 
		and Op_date=convert(char(10),getdate(),102) and Pay_method <>'0' and Sales_ID='$Corp_center' 
		update ctninfo..Inc_book_pay 
		set Left_total=0 
		where Res_ID='$res_id' and Op_type+'' in ('','H','G','S') and Op_date=convert(char(10),getdate(),102) 
		and Pay_method <>'0' and Sales_ID='$Corp_center' 
		update ctninfo..Inc_book 
			set Pay_method='$in{Pay_type}',Pay_user='$in{User_ID}',Pay_date=convert(char(10),getdate(),102) $sql_status  
			where Res_ID='$res_id' ";
	if ($CERT_TYPE ne "Y") {
		$in{Pay_type}="1004.03.03";
		#����;��Ϊ��ʱǷ��
	   $sql .=" update  ctninfo..Inc_book_pay set User_ID='$in{User_ID}',Pay_method='1004.03.03',
			Corp_ID='$Corp_ID' where Res_ID='$res_id' and Op_type ='G' 
		   and Pay_method in ('1004.01','1004.02') and Op_date=convert(char(10),getdate(),102) and Pay_method <>'0' \n ";
	}
	$sql .=" 
		if not exists( select * from ctninfo..Inc_book_pay where Res_ID='$res_id' )
		begin
		insert into ctninfo..Inc_book_pay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,
		Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,Pay_bank,CID_corp,Op_type) 
		select '$res_id',
		isnull(max(Pay_serial)+1,0),'$in{Pay_type}',$left_total,0,$left_total,'$in{User_ID}',getdate(),convert(char(10),getdate(),102), 
		'$in{Remark}','','$Corp_center','$Corp_ID','','$bk_corp','G' from ctninfo..Inc_book_pay where Res_ID='$res_id' \n
		insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) values('$res_id','G','$in{User_ID}','0',dateadd(ms,15,getdate())) 
		 end ";
}
## ������Ʒ�������� hecf 2014/8/5
sub inc_account_recv {
	##ԭ�տʽ����Ϣ  ,��ʾ������ϸʱ�õ���ǰ��������ʽ
	$sql = "select rtrim(Pay_method),Pay_name,Is_netpay,Is_show,Is_payed,Corp_ID,Pay_pic from ctninfo..d_paymethod 
		where  Corp_ID in ('SKYECH','$Corp_center') 
		order by Order_seq,Is_netpay ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT) {
			while(@row = $db->ct_fetch) {
				$pay_method_hash{$row[0]}[0]=$row[1]; ##����
				$pay_method_hash{$row[0]}[1]=$row[2];
			}
		}
	}
	##��ȡ��ƿ�Ŀ����Ϣ��ϣ��  liangby@2010-12-11
	#if ($Pay_version eq "1") {
	%kemu_hash = &get_kemu($Corp_center,"","hash2","","","","assist","N");
	##���˷�ʽ
	%pre_kemu_hash=&get_dict($Corp_center,4,"","hash2");
	#}
	my $must_pay_amount;
	$sql =" select Res_ID,Book_status,Out_total+Isnull(Other_fee,0),Recv_total,User_ID, 
		Pay_method,Inc_title,Inc_id,Corp_ID,Isnull(Other_fee,0),Old_resid,Tkt_status,Pro_id,Ticket_date,Account_period
		from ctninfo..Inc_book where Res_ID='$in{Reservation_ID}'
		and Sales_ID='$Corp_center' ";
	
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row=$db->ct_fetch)	{
				($old_id,$old_status,$Out_total,$old_recv_total,$user_id,$old_pay,$pro_title,$inc_id,$bk_corp,$old_other_fee,$old_resid,$Is_refund,$old_pro_id,$ticket_time,$old_account_period)=@row;
				if ($Is_refund eq "") {
					$Is_refund="0";
				}
				$must_pay_amount=sprintf("%.2f",$Out_total-$old_recv_total);
			}
		}
	}
	
	if ($old_id eq "") {
	   print MessageBox("������ʾ","����������");
	   exit;
	}
	my ($old_res_recv,$old_res_pricetotal)=();
	if ($old_resid ne "" && $Is_refund eq "1") {
		$sql_tt=" select Recv_total,Out_total+Isnull(Other_fee,0) from ctninfo..Inc_book
			where Sales_ID='$Corp_center'
				and Res_ID='$old_resid' ";
		$db->ct_execute($sql_tt);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$old_res_recv =$row[0];
					$old_res_pricetotal=$row[1];
				}
			}
		}
	}
	$left_total=sprintf("%.2f",$must_pay_amount);

	my %m_type = &get_dict($Corp_center,1,"","hash");
	my $usertype = &get_mcard_type($user_id);

	if ($inc_id ne "") {
		$sql =" select Reward_rate,Tag_str from ctninfo..Inc_goods where Corp_ID='$Corp_center' and Inc_id=$inc_id ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row=$db->ct_fetch)	{
					$Reward_rate=$row[0];
					$good_tag_str=$row[1];
				}
			}
		}
	}

	if ($old_status eq "C") {
	   print MessageBox("������ʾ","������ȡ�����޷�������������");
	   exit;
	}

	if ($in{old_left_total} !=$left_total ) {
	   print MessageBox("������ʾ","��������ѱ仯������ʧ��");
	   exit;
	}
	if (!exists($must_pay_amount_dt{"$in{Reservation_ID}"})) {
		$must_pay_amount_dt{"$in{Reservation_ID}"}=$must_pay_amount;
	}else{##���ۻ���   liangby@2017-2-14
		$must_pay_amount=$must_pay_amount_dt{"$in{Reservation_ID}"};
	}
#	$sql_upt =" begin transaction sql_insert 
#	declare \@t_reward integer \n";
	$sql_upt="";
	my $is_netpay="N";
	if ($old_pay ne "N" && $old_pay ne "0" && $kemu_hash{$old_pay}[1] ne "0" ) {##����֧�����Ĳ��ٿ۶��        liangby@2009-3-25
		if (length($old_pay)>1) {##�¿�Ŀ
			$is_netpay=$pay_method_hash{$kemu_hash{$old_pay}[1]}[1];
		}else{
			$is_netpay=$pay_method_hash{$old_pay}[1];
		}
	}
	my $pay_type_t=$p_Pay_type;
	if ($is_netpay eq "Y" && $is_refund eq "0") {##����֧���Ĳ��޸Ķ�����֧�����          liangby@2009-4-2
		$pay_type_t =$old_pay;
	}
	if ($old_status eq "S" || ($good_tag_str=~/B/ && $old_status eq "P") ) {
		$sql_status=",Book_status='H'";
	}
	my $Operate_date="convert(char(10),getdate(),102)";
	my $Operate_msg="";
	if (($Function_ACL{CWSY}&(1<<0))!=0 && $in{Operate_date} ne "" && $in{Operate_date} ne $today) {
		$Operate_date="'$in{Operate_date}'";
		$Operate_msg=",ָ����������:$in{Operate_date}";
		$sql_upt .="delete from ctninfo..Airbook_pay_day where Operate_date ='$in{Operate_date}' and Sales_ID='$Corp_center' \n";
	}
	$sql_upt .=" delete from ctninfo..Inc_book_pay
				 where Res_ID='$in{Reservation_ID}' 
					and Op_type in ('G','S') and Op_date=$Operate_date and Pay_method <>'0' and Sales_ID='$Corp_center' 
				update ctninfo..Inc_book_pay set Left_total=0
					 where Res_ID='$in{Reservation_ID}'  and Op_type+'' in ('','H','G','S') and Op_date=$Operate_date and Pay_method <>'0'  and Sales_ID='$Corp_center'  \n";
									
		
	$sql_upt .=" update ctninfo..Inc_book set Recv_total=Recv_total+$in{recv_total},Pay_method='$pay_type_t',Pay_user='$in{User_ID}',Pay_date=convert(char(10),getdate(),102) $sql_status where Res_ID='$in{Reservation_ID}' \n";
	if ($old_account_period ne "") {	##�����˵������� linjw@2016/12/16 ���˵���Ʊ������Ʊ��ͳ�ƣ�
		$sql_upt .= " update ctninfo..Account_info set Clear_amount=Clear_amount+$in{recv_total} where Account_period=$old_account_period and Sales_ID='$Corp_center' \n";
	}
	$payment_str="";
	my $tpsck_tradeno;
	my $tpsck_tradeno2;
	my $Pay_status;

	if ($old_pro_id !=26 && $bk_corp ne $Corp_center && $p_sh_recv>0) {
		$sxk_id=$p_Pay_type.$p_Pay_type2.$p_pingzheng;
		#print "$in{Reservation_ID},$p_Pay_type,$p_Pay_type2,$p_pingzheng<br>";
		if ($bk_corp ne $Corp_center && $is_used{$sxk_id} eq "" &&$p_sh_recv>0) {##���������   liangby@2015-6-11
			$is_used{$sxk_id}="Y"; ##�����������������жϣ�һ��֧����ʽ��������ֻ����һ����¼    liangby@2015-11-12
			my $rt_result=&use_credit_payment($bk_corp,$p_Pay_type,$p_Pay_type2,$p_pingzheng,$p_sh_recv,$in{Reservation_ID},$kemu_hash{$p_Pay_type}[0],$kemu_hash{$p_Pay_type2}[0],$p_sh_recv,"��������,����$in{Reservation_ID}���$in{recv_total}","0");
			if ($rt_result=~/<error>/) {
				$rt_result=~ s/<error>//g;
				$rt_result=~ s/<\/error>//g;
				print MessageBox("������ʾ","�Բ���$rt_result"); 
				exit;
			}else{
				$sql_upt .=$rt_result;
			
				if ($rt_result=~/Corp_credit_payment/) {
					$payment_str="[ʹ�����������]";
					$paykemu_tp=$p_Pay_type;
						
					$pay_bank_tp=$p_Pay_type2;
					$trade_no_tp=$p_pingzheng;
					$payment_rmk_tp{$sxk_id}=$payment_str.",�Ͷ���$in{Reservation_ID}ͬ������";
					$payment_str=$payment_str.",������ۿ��¼id:$bk_corp"."_"."'+convert(varchar,\@s_no)+'";
					$Pay_status="SS";
					$sql_upt .=" delete from #tmp \n
								insert into #tmp(S_no) values(\@s_no) \n ";
				}
			}
		}elsif($bk_corp ne $Corp_center && $is_used{$sxk_id} eq "Y" && $payment_rmk_tp{$sxk_id} ne ""){
			$payment_str=$payment_rmk_tp{$sxk_id}.",������ۿ��¼id:$bk_corp"."_"."'+convert(varchar,\@s_no)+'";
			#print "dd,$payment_str";
			#exit;
			#if ($cp_sno{$sxk_id} ne "") {
				$Pay_status="SS";
				##����������ۿ��¼��ע˵��  liangby@2015-12-10
				$sql_upt .=" declare \@s_no int \n
						   select top 1  \@s_no=S_no from #tmp \n";
				$sql_upt .=" if \@s_no !=NULL 
				   BEGIN
				    update ctninfo..Corp_credit_payment set Remark=Remark+',����$in{Reservation_ID}���$in{recv_total}' where Sales_ID='$Corp_center' and Corp_ID='$bk_corp' and S_no=\@s_no and Op_type='1'
				   END \n";
	
			#}
		}
	}elsif ($old_pro_id !=26 && $old_pro_id !=10 && $Is_refund eq "1"  && $bk_corp ne $Corp_center && $p_sh_recv<0 && $p_Pay_type eq "1003.02.25.01" ) {
		
		if ($old_res_recv ne "" && $old_res_pricetotal>0 && $old_res_recv==0) {
			print MessageBox("������ʾ","���˻���ԭ��Ʊ����δ�����������Խ��˻������������"); 
			exit;
		}
	   
		#$c_trade_no=$pay_method[$p]{pingzheng};
		##��Ʊ���������  liangby@2018-1-8
		my $rt_result=&use_credit_payment($bk_corp,$p_Pay_type,$p_Pay_type2,$c_trade_no,$p_sh_recv,$in{Reservation_ID},"","",$p_sh_recv,$c_rmk,"2");
		if ($rt_result=~/<error>/) {
			$rt_result=~ s/<error>//g;
			$rt_result=~ s/<\/error>//g;
			print MessageBox("������ʾ","�Բ���$rt_result"); 
			exit;
		}else{
			$tpsck_tradeno="'$in{Reservation_ID}'+'_'+convert(varchar,\@c_sno)" ;
			$tpsck_tradeno2="'ƾ֤��:$in{Reservation_ID}'+'_'+convert(varchar,\@c_sno)" ;
			$sql_upt .=$rt_result;
			if ($rt_result=~/Corp_credit_payment/) {
				$payment_str="[�˵�������]";
				$Pay_status="TS";
			}
		}
		$sxk_credit="";
	}
	my $sub_comment="''";
	my $Pay_string="'$p_pingzheng'";
	if ($tpsck_tradeno ne "") {##��Ʊ�����������ˮ��   liangby@2018-1-8
		$Pay_string=$tpsck_tradeno;
	}
	if ($p_pingzheng ne "") {
		$sub_comment .="' ƾ֤��$p_pingzheng'";
	}
	if ($tpsck_tradeno2 ne "") {##��Ʊ�����������ˮ��   liangby@2018-1-8
		$sub_comment=$tpsck_tradeno2;
	}
	my $tRemark=$in{Remark}.":".$Comment;
	my $left=sprintf("%.2f",$must_pay_amount+(-1*$in{recv_total}));
	$must_pay_amount=sprintf("%.2f",$must_pay_amount);
	$must_pay_amount_dt{"$in{Reservation_ID}"}=$must_pay_amount_dt{"$in{Reservation_ID}"}+(-1*$in{recv_total});
	$sql_upt .=" insert into ctninfo..Inc_book_pay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,Pay_bank,CID_corp,Op_type,Pay_status)
		select '$in{Reservation_ID}',isnull(max(Pay_serial)+1,0),'$p_Pay_type',$must_pay_amount,$in{recv_total},0,'$in{User_ID}',getdate(),$Operate_date,
			'$tRemark$payment_str$Operate_msg'+$sub_comment,$Pay_string,'$Corp_center','$Corp_ID','$p_Pay_type2','$bk_corp','H','$Pay_status'
	     from ctninfo..Inc_book_pay where Res_ID='$in{Reservation_ID}'  ";
	my $pay_type3=$p_Pay_type;
	if ($Pay_version eq "1" ) {##���˵İ�ԭ����Ŀ���ˣ������İ���ʱǷ�����   liangby@2010-12-15
		if ($old_pay eq "1004.04") {##����
			$pay_type3="1004.04";
			
		}else{
			$pay_type3="1004.03.03";
		}
		if ($CERT_TYPE eq "Y") {
			$pay_type3="Y1131";	## ���ѣ�ֱ�ӹ� 1131-Ӧ���˿�	liangby@2013-12-16
		}
		
	}
	if ($left !=0) {
		$sql_upt .=" insert into ctninfo..Inc_book_pay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,Pay_bank,CID_corp,Op_type)
		select '$in{Reservation_ID}',isnull(max(Pay_serial)+1,0),'$pay_type3',$left,0,$left,'$in{User_ID}',getdate(),$Operate_date,
			'$in{Remark}$Operate_msg','','$Corp_center','$Corp_ID','','$bk_corp','G'
	     from ctninfo..Inc_book_pay where Res_ID='$in{Reservation_ID}'  ";
	}
	$t_recv_total=$in{recv_total};
	if ($t_recv_total !=0  && $p_Pay_type eq "4003.01.04"
		&& grep {$_ eq $usertype} keys %m_type) {##���ֵֿ�    liangby@2012-10-23
		$tt_usertype=$usertype;
		if ($usertype eq "N") {
			$tt_usertype="C";
		}
		$sql_tt="select Reward_rate,right(convert(char(10),getdate(),102),8) from ctninfo..Reward_rate where Corp_ID='$Corp_center' and Product_type='R' and User_type='$tt_usertype' ";
		
		$db->ct_execute($sql_tt);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$reward_dk=$row[0];    ##��ֻ�һԪ
					$Apply_ID=$row[1];
					$Apply_ID =~ s/\.//g;
				}
			}
		}
		if ($reward_dk eq "" || $reward_dk==0) {
			print MessageBox("������ʾ","�Բ���,�û�Ա������δά�����ֵֿ����ѽ�����,���ڻ��ֹ�����ά��"); 
			exit;
		}
		##����Ҫ����
		$need_reward=sprintf("%0.f",$t_recv_total*$reward_dk);
		##�ĴӼ�¼��ʵʱ��ȡ�ܻ��ֺ����û���    liangby@2014-6-26
		my $Total_reward=0;
		$sql_tt =" select isnull(sum(Reward),0) from ctninfo..Member_reward where User_ID='$user_id' and Corp_num='$Corp_center' ";
		$db->ct_execute($sql_tt);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$Total_reward=$row[0];
				}
			}
		}
		my $Pay_reward=0;
		$sql_tt=" select sum(Gift_num*Need_reward) from ctninfo..Gift_apply where Corp_num='$Corp_center' and User_ID='$user_id' and De_status <>'C' ";
		$db->ct_execute($sql_tt);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$Pay_reward=$row[0];
				}
			}
		}
		$u_left=$Total_reward-$Pay_reward;
		if ($u_left <$need_reward) {
			if ($Corp_center eq "022000" && $in{User_ID} eq "hx001") {##��Ѷ���ܿ��Եֿ۸����֣��ź�Ҫ��   liangby@2012-10-25
			}else{
				print MessageBox("������ʾ","�Բ���,�û�Աʣ����ֲ���,�������$need_reward,ʣ�����$u_left"); 
				exit;
			}
		}
		my $tkt_name;
		if ($Is_refund eq "1" ) {
			$tkt_name=",�˻�";
		}
		$sql_upt .= " declare \@Apply_ID integer 
					select \@Apply_ID = max(convert(integer,Apply_ID))+1 from ctninfo..Gift_apply where Apply_ID like '$Apply_ID%'
					if \@Apply_ID=null select \@Apply_ID = $Apply_ID * 1000
					INSERT INTO ctninfo..Gift_apply (Corp_num,Corp_ID,User_ID,Apply_ID,Gift_ID,
							Gift_name,Gift_num,Need_reward,Apply_date,Delivery_method,De_person,
							De_address,De_zip,De_tel,De_email,De_status,Comment,Apply_by,Apply_time,Gift_no,APrice,Confirm_by,Confirm_time)
					VALUES ('$Corp_center','$Corp_ID','$user_id',convert(varchar(9),\@Apply_ID),-1,
							'������Ʒ�������ֵֿ�$t_recv_totalԪ$tkt_name',1,$need_reward,getdate(),'Q','',
							'','','','','Y','������Ʒ�������ֵֿ�$t_recv_totalԪ$tkt_name','$in{User_ID}',getdate(),'$in{Reservation_ID}',$t_recv_total,'$in{User_ID}',getdate()) \n";

			##ͬ���Ѷһ�����  liangby@2015-9-24
			$sql_upt .= " update ctninfo..User_info set Pay_reward=(select isnull(sum(Gift_num*Need_reward),0) from ctninfo..Gift_apply where Corp_num='$Corp_center' and User_ID='$user_id' and De_status <>'C' ) where Corp_num='$Corp_center' and User_ID='$user_id' \n";

	}
	if ($old_pro_id ne "10" && $old_pro_id ne "12" && $old_pro_id ne "26" && $old_pro_id ne "27" && $old_pro_id ne "28"){
		if ($bk_corp ne $Corp_center && $in{recv_total} !=0) {
			##����ۿ���   liangby@2017-10-20
			$sql = "select Pay_amount from ctninfo..Airbook_unpay where Reservation_ID='$in{Reservation_ID}' and Corp_ID='$bk_corp' ";
			my $unpay_amount = &Exec_sql();
			$sql ="";
			if ($unpay_amount != 0) {	
				$l_credit=sprintf("%.2f",$unpay_amount-$in{recv_total});
				my $dc_sqlvar;
				if ($sql_upt=~/declare\s+\@l_credit_inc\s+/){
					$dc_sqlvar="Y";
				}
				$credit_num = &Cal_credit_num_inc("$in{Reservation_ID}","$bk_corp");
				if ($credit_num ==1 ) {
					$sql_upt .= &Cal_Airbook_credit_inc("$bk_corp","$in{Reservation_ID}","0","$l_credit","11","","",$dc_sqlvar);
				}
			
			}
		}
	}
	if ($old_pro_id eq "10") {##���տ������������   liangby@2011-12-28
		## ��ѯϵͳ����Ա��Ϣ����������¼д����û����� 
		my $pay_user = $in{User_ID};
		$sql = "select User_ID from ctninfo..User_info_op where Corp_num='$Corp_center' and User_type ='S' and Card_no like '%P%' and User_status='Y' ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$pay_user=$row[0];
				}
			}
		}
		$sql = "select User_ID from ctninfo..User_info_op where Corp_num='$Corp_center' and User_type ='O' and Card_no like '%P%' and User_status='Y'  ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$pay_user=$row[0];
				}
			}
		}
		my @ds_resid=();
		my @ds_amount=();
		my @ds_restype=();
		my @ds_no=();
		my @ds_dtid=();
		$sql_tt=" select rtrim(Cust_name),Ds_amount,Ds_restype,Ds_recv,Serial_no,rtrim(Card_ID) from ctninfo..Inc_book_detail where Res_ID ='$in{Reservation_ID}' and Ds_amount !=Ds_recv order by Ds_amount ";
		$db->ct_execute($sql_tt);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if ($restype==CS_ROW_RESULT)	{
				while(@row=$db->ct_fetch)	{
					push(@ds_resid,$row[0]);  push(@ds_amount,$row[1]-$row[3]); push(@ds_restype,$row[2]); push(@ds_no,$row[4]);
					push(@ds_dtid,$row[5]);
				}
			}
		}
		my $pay_total_ds=$in{recv_total};
		my $do_amount_ds=0;    ##���ý��
		my $is_ok_ds="N";
		for (my $j=0;$j<scalar(@ds_resid) ;$j++) {
			my $must_pay_amount=0;  ##Ӧ���ܶ�
			my $bk_status;
			my $old_ticket_time;
			my $old_ticket_time2;
			my $ds_resid=$ds_resid[$j];
			my $ds_dtid=$ds_dtid[$j];
			$M_AMT=$ds_amount[$j];
			if (!exists($M_AMT_dt{"$ds_resid"})) {
				$M_AMT_dt{"$ds_resid"}=$M_AMT;
			}else{##ͬһ�������ۻ���   liangby@2017-2-14
				$M_AMT=$M_AMT_dt{"$ds_resid"};
			}
			##�Ų������,�����������տ���   liangby@2013-8-15
			##����������ǰ��������������      liangby@2015-3-31
			if ($is_ok_ds eq "Y") {##����,����ѭ��    liangby@2011-11-20
				last;
			}
			if ($pay_total_ds <($do_amount_ds+$M_AMT)) {##����,ִ�����ⵥ����������Ĳ���
			  # if ($left_ystotal<=($pay_total_ds-$do_amount_ds)) {##������������������ں�������   liangby@2014-2-25
				   
			  # }else{
				   $M_AMT=$pay_total_ds-$do_amount_ds;
				   if ($M_AMT==0) {##��һ�������պð�֧��������꣬����ѭ��    liangby@2014-4-29
					 next;
				   }
				   $is_ok_ds="Y";
			  # }
			}
			$M_AMT=sprintf("%.2f",$M_AMT); ##��ʽ�����������λС������sql�����+��Ϊ0�����   liangby@2018-2-27
			$do_amount_ds=$do_amount_ds+$M_AMT;
		
			if ($ds_restype[$j] eq "A") {##��Ʊ
				 my ($tkt_diff,$pre_pay_by,$t_old_delivery,$t_Is_voucher,$t_is_refund)=();
		
				 $sql_tt = "select a.Book_status,'',a.User_ID,a.Out_total-a.Agt_total,a.Pay_method,
							a.Booking_ref,a.Air_type,a.Insure_recv,a.Is_reward,'',a.Recv_total,a.Agt_total,
							a.Corp_ID,a.Insure_out,a.AAboook_method,a.Out_total,a.Net_book,convert(char(10),a.Ticket_time,102),
							a.Other_fee,datediff(day,a.Ticket_time,getdate()),isnull(a.Service_fee,0),a.Abook_method,a.Delivery_method,a.Alert_status,a.Is_voucher
						from ctninfo..Airbook_$Corp_center a
						where Reservation_ID='$ds_resid' ";
					$db->ct_execute($sql_tt);
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT)	{
							while(@row = $db->ct_fetch)	{
								$bk_status=$row[0];		$user_type=$row[1];				$member_id=$row[2];		
								$comm=$row[3];			$old_pay_method = $row[4];		$PNR=$row[5];
								$Air_type=$row[6];		$sale_code=$row[7];				$Is_reward=$row[8];

								$recv_total=$row[10];
								$agt_total =$row[11];   $bk_corp=$row[12];
								$Insure_out=$row[13];   $comm_method=$row[14];  $out_total=$row[15];
								$Net_book=$row[16];  $old_ticket_time=$row[17];
								$old_other_fee=$row[18];	$tkt_diff=$row[19]; $service_fee=$row[20];
								$pre_pay_by=$row[21];   $t_old_delivery=$row[22];
								$t_is_refund=$row[23];	$t_Is_voucher=$row[24];
								$must_pay_amount=$out_total+$Insure_out+$old_other_fee+$service_fee-$recv_total;
								if ($comms_method eq "C" ||$Net_book eq "Q" || $Net_book eq "C" || $Net_book eq "K" || $Sale_code >0) {
									$must_pay_amount=$agt_total+$Insure_out+$old_other_fee+$service_fee-$recv_total;
								}
							}
						}
					}
					if (!exists($must_pay_amount_dt{"$ds_resid"})) {
						$must_pay_amount_dt{"$ds_resid"}=$must_pay_amount;
					}else{##ͬһ�������ۻ���   liangby@2017-2-14
						$must_pay_amount=$must_pay_amount_dt{"$ds_resid"};
					}
					my $pay_type3=$p_Pay_type;
					if ($Pay_version eq "1" ) {##���˵İ�ԭ����Ŀ���ˣ������İ���ʱǷ�����   liangby@2010-12-15
						if ($pre_kemu_hash{$pre_pay_by}[3] eq "T") {##����
							if ($pre_kemu_hash{$pre_pay_by}[2] ne "") {
								$pay_type3=$pre_kemu_hash{$pre_pay_by}[2];
							}else{
								$pay_type3="1004.03.03";

								#print MessageBox("������ʾ","$pre_pay_by�Զ�����ʧ��,����ϵ����Ա��"); 
								#exit;
							}
							
						}else{
							$pay_type3="1004.03.03";
						}
						if ($CERT_TYPE eq "Y") {
							$pay_type3="Y1131";	## ���ѣ�ֱ�ӹ� 1131-Ӧ���˿�	liangby@2013-12-16
						}

						
					}
					$old_ticket_time=~ s/\s*//g;
					$old_ticket_time2=$old_ticket_time;
					if ($old_ticket_time eq "") {
						$old_ticket_time="null";
					}else{
						$old_ticket_time="'$old_ticket_time'";
					}
					$user_type = &get_mcard_type($member_id);
					$res_pay_tag="0";
					if ($bk_status eq "") {	next;	}
					if ($bk_status eq "C") { next;	}
					## ��ѯ������Ϣ
					$amt_total = 0;
					$t_agt=$must_pay_amount;
					$t_amount=$M_AMT;
					if ($t_amount eq "") {
						$t_amount=$must_pay_amount;
					}
					my $sql_pay;
					$sql = "select Res_serial,Last_name,First_name,Out_price,Tax_fee,YQ_fee,Insure_outprice*Insure_num,Other_fee,Origin_price,Recv_price,isnull(Service_fee,0)
						from ctninfo..Airbook_detail_$Corp_center where Reservation_ID='$ds_resid'";
					if ($ds_dtid ne "") {
						my ($rs_no,$ls_no)=split/\|/,$ds_dtid;
						$sql .=" and Res_serial=$rs_no and Last_name='$ls_no' ";
					}
					
					$db->ct_execute($sql);
					while($db->ct_results($restype) == CS_SUCCEED) {
						if($restype==CS_ROW_RESULT)	{
							while(@row = $db->ct_fetch)	{
								my $recv = $row[8] + $row[4] + $row[5] + $row[6] + $row[7]+$row[10]-$row[9];
								if ($comm_method eq "T") {
									$recv = $row[3] + $row[4] + $row[5] + $row[6] + $row[7]+$row[10]-$row[9];
								}
								
								if (!exists($recv_dt{"$ds_resid,$row[0],$row[1]"})) {
									$recv_dt{"$ds_resid,$row[0],$row[1]"}=$recv;
								}else{##ͬһ�������ۻ���   liangby@2017-2-14
									$recv=$recv_dt{"$ds_resid,$row[0],$row[1]"};
								}
								
								my $left=0;
								my $price_total=$recv;
								##������Բ��ϵ�����  liangby@2011-11-18 ----
								if (($recv >$t_amount && $M_AMT>0) || ($recv <$t_amount && $M_AMT<0)) {
									$left=$recv-$t_amount;
									$recv=$t_amount;
								}elsif((($recv < $t_amount && $M_AMT >0 ) || ($recv > $t_amount && $M_AMT <0))&& $recv==$t_agt){##���һ��
									$left=$recv-$t_amount;
									$recv=$t_amount;
								}
								##-------------------------
								$t_agt=$t_agt-$price_total;
								$t_amount=$t_amount-$recv;
								$amt_total = $amt_total + $recv;
								$left=sprintf("%.2f",$left);
								$recv=sprintf("%.2f",$recv);
								
								$recv_dt{"$ds_resid,$row[0],$row[1]"}=$recv_dt{"$ds_resid,$row[0],$row[1]"}-$recv;
								
								$sql_pay .=" delete from ctninfo..Airbook_pay_$Corp_center 
								 where Reservation_ID='$ds_resid' and Res_serial=$row[0]
									and Last_name='$row[1]' and Op_type in ('G','S') and Operate_date=$Operate_date and Pay_object <>'0'\n
								update ctninfo..Airbook_pay_$Corp_center set Left_total=0
									 where Reservation_ID='$ds_resid' and Res_serial=$row[0] 
										and Last_name='$row[1]'  and Op_type in ('H','G','S') and Operate_date=$Operate_date and Pay_object <>'0'\n";
							
								$sql_pay .= "update ctninfo..Airbook_detail_$Corp_center 
									set Recv_price=Recv_price+$recv
									where Reservation_ID='$ds_resid' and Res_serial=$row[0] and First_name='$row[2]' and Last_name='$row[1]' \n";
								$sql_pay .= "insert into ctninfo..Airbook_pay_$Corp_center (Reservation_ID,Res_serial,Last_name,Pay_serial,Pay_object,
										Price_total,Recv_total,Left_total,User_ID,Operate_time,Comment,Corp_ID,Op_type,
										Ticket_time,Pay_bank,Pay_string,Pay_trans,Sales_ID,Operate_date,Person_num,Pay_status,CID_corp) 
									select '$ds_resid',$row[0],'$row[1]',Isnull(max(Pay_serial),0)+1,'$p_Pay_type',
										$price_total,$recv,0,'SYSTEM',getdate(),'���յ�$in{Reservation_ID}','$Corp_ID','H',
										$old_ticket_time,'$p_Pay_type2','$in{Reservation_ID}','$M_AMT','$Corp_center',$Operate_date,1,'DS','$bk_corp'
									from ctninfo..Airbook_pay_$Corp_center 
									where Reservation_ID='$ds_resid' 
										and Res_serial=$row[0] 
										and Last_name='$row[1]' \n";
								
								if ($left !=0) {
									$sql_pay .= "insert into ctninfo..Airbook_pay_$Corp_center (Reservation_ID,Res_serial,Last_name,Pay_serial,Pay_object,
										Price_total,Recv_total,Left_total,User_ID,Operate_time,Comment,Corp_ID,Op_type,
										Ticket_time,Pay_bank,Pay_string,Pay_trans,Sales_ID,Operate_date,Person_num,Pay_status,CID_corp) 
									select '$ds_resid',$row[0],'$row[1]',Isnull(max(Pay_serial),0)+1,'$pay_type3',
										$left,0,$left,'SYSTEM',getdate(),'','$Corp_ID','G',
										$old_ticket_time,'','','','$Corp_center',$Operate_date,1,'','$bk_corp'
									from ctninfo..Airbook_pay_$Corp_center 
									where Reservation_ID='$ds_resid' 
										and Res_serial=$row[0] 
										and Last_name='$row[1]' \n";
								}
							}
						}
					}
					
					## д�붩��������¼
					$sql_upt .= qq!insert into ctninfo..Res_op values('$ds_resid','A','$in{User_ID}','H',getdate()) \n!;
		
					#member_id
					my $opstr_status;
					if ($bk_status eq "S" || (($t_is_refund eq "1" || $t_is_refund eq "2" ) && ($t_old_delivery eq "N" || $t_Is_voucher eq "S"))) {##�����͵��Զ�����������      liangby@2008-12-15
						 $opstr_status=" ,Book_status='H' ";
					}
					if ($old_ticket_time2 eq "") {##δ��Ʊ֧����,Send_dateΪ��������   liangby@2012-12-26
						$opstr_status .=",Send_date=Isnull(Send_date,getdate()) ";
					}else{
						$opstr_status .=",Send_date=Isnull(Send_date,Ticket_time) ";
					}
					$sql_upt .= " Update ctninfo..Airbook_$Corp_center set Left_total=0,Recv_total=Recv_total+$M_AMT,First_paydate=Isnull(First_paydate,convert(char(10),getdate(),102)),Pay_method='$p_Pay_type',Pay_date=convert(char(10),getdate(),102),Pay_user='$pay_user' $opstr_status  where Reservation_ID='$ds_resid' \n";
					
					$sql_upt .=$sql_pay;
					##���ڸ���Airbook.Recv_total���º��棬������sql������ж��Ƿ��������    liangby@2017-7-3
					$credit_num = &Cal_credit_num("$ds_resid","$bk_corp");
					if ($credit_num ==1 ) {	## Ԥ�����Ʊ�������ö�ȳ�Ʊ���������
					##���ö�ȵĲŵ�����Ԥ����Ļ�������   liangby@2017-7-3
						$credit_out=$agt_total;
						$sql_tt=" select Corp_type,Corp_tag from ctninfo..Corp_info where Corp_ID='$bk_corp' ";
						$db->ct_execute($sql_tt);
						while($db->ct_results($restype) == CS_SUCCEED) {
							if($restype==CS_ROW_RESULT)	{
								while(@row=$db->ct_fetch)	{
									$old_corp_type =$row[0];
									$old_corp_tag=$row[1];
								}
							}
						}
						if ($comm_method eq "T") {##�󷵿����ۼ�   liangby@2010-01-13
							$credit_out =$out_total;
						}
						if ($Pay_version eq "1" || $old_corp_type eq "B" || ($old_corp_type eq "A" && $old_corp_tag =~/G/)) {##��ͻ��۱���   liangby@2009-11-25
							$credit_out +=$Insure_out+$old_other_fee+$service_fee;
						}
						my $dc_sqlvar;
						if ($sql_upt=~/declare\s+\@l_credit\s+/){
							$dc_sqlvar="Y";
						}
						$sql_upt .= &Cal_Airbook_credit("$bk_corp","$ds_resid","0","$credit_out","11","","",$dc_sqlvar);
					}
					if ($old_other_fee !=0 && $M_AMT !=0) {##��������ͬ������  liangby@2017-4-13
						$sql_tt = "SELECT a.Res_ID, a.Inc_id, a.Out_price, a.Pro_num FROM ctninfo..Inc_book AS a
								WHERE a.Sales_ID='$Corp_center'  AND a.Air_resid='$ds_resid' AND a.Order_type IN ('A','I') AND a.Book_status<>'H'";
						$db->ct_execute($sql_tt);
						while($db->ct_results($restype) == CS_SUCCEED) {
							if($restype==CS_ROW_RESULT) {
								while(@row = $db->ct_fetch) {
									my $inc_resid = $row[0];
									my $inc_recv_price = $row[2] * $row[3];
									$sql_upt .= "update ctninfo..Inc_book set Recv_total=Recv_total+$inc_recv_price,Book_status='H',Pay_method='$p_Pay_type',Pay_user='$in{User_ID}',Pay_date=convert(char(10),getdate(),102) where Res_ID='$inc_resid'\n";
								}
							}
						}
					}
					$must_pay_amount_dt{"$ds_resid"} =$must_pay_amount_dt{"$ds_resid"}-$M_AMT;
					$M_AMT_dt{"$ds_resid"}=$M_AMT_dt{"$ds_resid"}-$M_AMT;
					$sql_upt .= " update ctninfo..Inc_book_detail set Ds_recv=Ds_recv+$M_AMT where  Res_ID ='$in{Reservation_ID}' and Serial_no=$ds_no[$j] \n";
					
					if (($must_pay_amount <=$M_AMT && $M_AMT) >0 ||($must_pay_amount >=$M_AMT && $M_AMT <0)) {
						
						if ((grep {$_ eq $user_type} keys %m_type) ) {##���ֻ�ȡ
							## ---------------------------------------------
							## ��ѯ���ֹ���	dabin@2008-9-22
							if ($Air_type eq "Y") {	$Air_type="B";	}	else{$Air_type="A";	}
							##�����ţ��������ͣ�A���ڻ�Ʊ/B���ʻ�Ʊ���������ģ�����Ա����Ա���룬��Ա���ͣ�֧����ʽ��֧����ע,֧�����
							## lib/ctnlib/golden/air_pay.pl
							$sql_upt .= &account_reward("$ds_resid","$Air_type","$Corp_center","$in{User_ID}","$member_id","$user_type","$p_Pay_type","","");
						}
					}
					
			}elsif ($ds_restype[$j] eq "G") {##�����յ�������Ʒ��   liangby@2012-1-6
				my $old_status;
				my $old_pro_id;
				my $Send_corp;
				my $bk_corp;
				$sql_tt=" select Res_ID,Book_status,Out_total+Isnull(Other_fee,0),Recv_total,User_ID, 
					Pay_method,Inc_title,Inc_id,Corp_ID,Pro_id,Send_corp from ctninfo..Inc_book where Res_ID='$ds_resid' ";
				$db->ct_execute($sql_tt);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							($old_id,$old_status,$Out_total,$old_recv_total,$member_id,$old_pay,$pro_title,$inc_id,$bk_corp,$old_pro_id,$Send_corp)=@row;
							$must_pay_amount=$Out_total-$old_recv_total;
						}
					}
				}
				$sql_tt =" select Tag_str from ctninfo..Inc_goods where Corp_ID='$Corp_center' and Inc_id=$inc_id ";
				$db->ct_execute($sql_tt);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if ($restype==CS_ROW_RESULT)	{
						while(@row=$db->ct_fetch)	{
							$good_tag_str=$row[0];
						}
					}
				}
				if (!exists($must_pay_amount_dt{"$ds_resid"})) {
					$must_pay_amount_dt{"$ds_resid"}=$must_pay_amount;
				}else{##ͬһ�������ۻ���   liangby@2017-2-14
					$must_pay_amount=$must_pay_amount_dt{"$ds_resid"};
				}
				$user_type = &get_mcard_type($member_id);
				my $pay_type3=$p_Pay_type;
				if ($Pay_version eq "1" ) {##���˵İ�ԭ����Ŀ���ˣ������İ���ʱǷ�����   liangby@2010-12-15
					if ($pre_kemu_hash{$pre_pay_by}[3] eq "T") {##����
						if ($pre_kemu_hash{$pre_pay_by}[2] ne "") {
							$pay_type3=$pre_kemu_hash{$pre_pay_by}[2];
						}else{
							$pay_type3="1004.03.03";
						}
						
					}else{
						$pay_type3="1004.03.03";
					}
					if ($CERT_TYPE eq "Y") {
						$pay_type3="Y1131";	## ���ѣ�ֱ�ӹ� 1131-Ӧ���˿�	liangby@2013-12-16
					}
					
				}
				if ($old_status eq "C") {##������ȡ��
					next;
				}
				if ($old_status eq "") {
				    next;
				}
				my $tt_st;
				if ($old_status eq "S" || ($old_status eq "P" && $good_tag_str=~/B/)) {
					$tt_st=",Book_status='H'";
				}
				$sql_upt .=" delete from ctninfo..Inc_book_pay
					 where Res_ID='$ds_resid' 
						and Op_type in ('G','S') and Op_date=$Operate_date and Pay_method <>'0' and Sales_ID='$Corp_center' 
					update ctninfo..Inc_book_pay set Left_total=0
						 where Res_ID='$ds_resid'  and Op_type+'' in ('','H','G','S') and Op_date=$Operate_date and Pay_method <>'0'  and Sales_ID='$Corp_center'  \n";

				$sql_upt .=" update ctninfo..Inc_book set Recv_total=Recv_total+$M_AMT $tt_st ,Pay_method='$p_Pay_type' where Res_ID='$ds_resid' \n";
				$sql_upt .=" insert into ctninfo..Inc_book_pay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,CID_corp,Pay_bank,Pay_status,Op_type)
				   select '$ds_resid',isnull(max(Pay_serial)+1,0),'$p_Pay_type',$must_pay_amount,$M_AMT,0,'SYSTEM',getdate(),$Operate_date,
					   '���յ�$in{Reservation_ID}$Operate_msg','$in{Reservation_ID}','$Corp_center','$Corp_ID','$bk_corp','$p_Pay_type2','DS','H'
					   from ctninfo..Inc_book_pay where Res_ID='$ds_resid' ";
				my $left=sprintf("%.2f",$must_pay_amount+-1*$M_AMT);
				$must_pay_amount_dt{"$ds_resid"}=$must_pay_amount_dt{"$ds_resid"}-$M_AMT;
				$M_AMT_dt{"$ds_resid"}=$M_AMT_dt{"$ds_resid"}-$M_AMT;
				if ($left !=0) {
				  $sql_upt .=" insert into ctninfo..Inc_book_pay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,CID_corp,Pay_bank,Pay_status,Op_type)
				    select '$ds_resid',isnull(max(Pay_serial)+1,0),'$pay_type3',$left,0,$left,'SYSTEM',getdate(),$Operate_date,
					   '$Operate_msg','$in{Reservation_ID}','$Corp_center','$Corp_ID','$bk_corp','','','G'
					   from ctninfo..Inc_book_pay where Res_ID='$ds_resid' ";
				}
				$sql_upt .=" insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) 
					values('$ds_resid','G','$in{User_ID}','H',getdate()) ";
				$sql_upt .= " update ctninfo..Inc_book_detail set Ds_recv=Ds_recv+$M_AMT where  Res_ID ='$in{Reservation_ID}' and Serial_no=$ds_no[$j] \n";
				if (grep {$_ eq $user_type} keys %m_type) {
					##�����ţ��������ͣ�A���ڻ�Ʊ/B���ʻ�Ʊ���������ģ�����Ա����Ա���룬��Ա���ͣ�֧����ʽ��֧����ע,֧�����
					## lib/ctnlib/golden/air_pay.pl
					$sql_upt .=&account_reward("$ds_resid","G","$Corp_center","$in{User_ID}","$member_id","$user_type","$p_Pay_type",$pro_title,$M_AMT);
					## ��ԱԤ���������Ƿ���֣����޸������������	
					$sql_upt .= "update ctninfo..User_info set Last_bk_time=getdate() where User_ID='$member_id' \n";
				}
				if ($old_pro_id ne "10" && $old_pro_id ne "12" && $old_pro_id ne "26" && $old_pro_id ne "27" && $old_pro_id ne "28"){
					if ($bk_corp ne $Corp_center && $M_AMT !=0) {
						##����ۿ���   liangby@2017-6-27
						$sql = "select Pay_amount from ctninfo..Airbook_unpay where Reservation_ID='$ds_resid' and Corp_ID='$bk_corp' ";
						my $unpay_amount = &Exec_sql();
						
						$sql ="";
						#print "---- $unpay_amount --------<br>";
						if ($unpay_amount != 0) {	
							$l_credit=sprintf("%.2f",$unpay_amount-$M_AMT);
							my $dc_sqlvar;
							if ($sql_upt=~/declare\s+\@l_credit_inc\s+/){
								$dc_sqlvar="Y";
							}
							$credit_num = &Cal_credit_num_inc("$ds_resid","$bk_corp");
							if ($credit_num ==1 ) {
								$sql_upt .= &Cal_Airbook_credit_inc("$bk_corp","$ds_resid","0","$l_credit","11","","",$dc_sqlvar);
							}
						
						}
					}
				}
					
			}elsif ($ds_restype[$j] eq "F") {##�����յĻ𳵵�   liangby@2012-1-6
				##��ѯ����״̬
			   my $bk_status;
			   my $Send_corp;
			   $sql =" select a.Reservation_ID,a.Total_price,a.Res_state,a.PP_method,a.Pay_amount,a.User_ID,a.Send_corp
						from ctninfo..Train_book a
						where  a.Reservation_ID='$ds_resid' and a.Sales_ID='$Corp_center' ";
				$db->ct_execute($sql);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if ($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							 $must_pay_amount=$row[1]-$row[4];	 
							 $bk_status=$row[2];
							 $old_pay_method=$row[3];  $recv_total=$row[4];
							 $member_id=$row[5];
							 $Send_corp=$row[6];
						} 
					}
				}
				if (!exists($must_pay_amount_dt{"$ds_resid"})) {
					$must_pay_amount_dt{"$ds_resid"}=$must_pay_amount;
				}else{##ͬһ�������ۻ���   liangby@2017-2-14
					$must_pay_amount=$must_pay_amount_dt{"$ds_resid"};
				}
				$user_type = &get_mcard_type($member_id);
	
				if ($bk_status eq "") {
					next;
				}
				if ($bk_status eq "C") { next;	}
				$amt_total = 0;
				$t_agt=$must_pay_amount;
				$t_amount=$M_AMT;
				if ($t_amount eq "") {
					$t_amount=$must_pay_amount;
				}

				$sql_tt=" select Serial_no,Res_serial,Seat_price+Other_fee+Window_price,Recv_price from ctninfo..Train_book_link where Reservation_ID='$ds_resid' ";
				$db->ct_execute($sql_tt);
				while($db->ct_results($restype) == CS_SUCCEED) {
					if ($restype==CS_ROW_RESULT)	{
						while(@row = $db->ct_fetch)	{
							my $recv=$row[2]-$row[3];
							if (!exists($recv_dt{"$ds_resid,$row[0],$row[1]"})) {
								$recv_dt{"$ds_resid,$row[0],$row[1]"}=$recv;
							}else{##ͬһ�������ۻ���   liangby@2017-2-14
								$recv=$recv_dt{"$ds_resid,$row[0],$row[1]"};
							}
							my $left=0;
							my $price_total=$recv;
							##������Բ��ϵ�����  liangby@2011-11-18 ----
							if (($recv >$t_amount && $M_AMT>0) || ($recv <$t_amount && $M_AMT<0)) {
								$left=$recv-$t_amount;
								$recv=$t_amount;
							}elsif((($recv < $t_amount && $M_AMT >0 ) || ($recv > $t_amount && $M_AMT <0))&& $recv==$t_agt){##���һ��
								$left=$recv-$t_amount;
								$recv=$t_amount;
							}
							##-------------------------
							$t_agt=$t_agt-$price_total;
							$t_amount=$t_amount-$recv;
							$amt_total = $amt_total + $recv;
							$left=sprintf("%.2f",$left);
							$recv=sprintf("%.2f",$recv);
							$recv_dt{"$ds_resid,$row[0],$row[1]"}=$recv_dt{"$ds_resid,$row[0],$row[1]"}-$recv;
							$sql_upt .=" update ctninfo..Train_book_link set  Recv_price=Recv_price+$recv,
								Pay_time=getdate(),Pay_method='$p_Pay_type'
								where Reservation_ID='$ds_resid' and Serial_no=$row[0] and Res_serial=$row[1] ";
							$sql_upt .=" insert into ctninfo..Train_book_pay(Reservation_ID,Res_serial,P_serial,Pay_object,Seat_no,Price_total,Recv_total,Left_total,User_ID,Corp_ID,Sales_ID,Comment,Pay_time,Op_type,Trade_no,Pay_status,Pay_bank,CID_corp)
									   select '$ds_resid',$row[1],isnull(max(P_serial)+1,0),'$p_Pay_type',$row[0],$price_total,$recv,$left,'SYSTEM','$Corp_ID','$Corp_center','���յ�$in{Reservation_ID}',getdate(),'H','$in{Reservation_ID}','DS','$p_Pay_type2','$bk_corp'
									 from ctninfo..Train_book_pay where Reservation_ID='$ds_resid' 
								 \n";
						}
					}
				}
				$must_pay_amount_dt{"$ds_resid"}=$must_pay_amount_dt{"$ds_resid"}-$M_AMT;
				$M_AMT_dt{"$ds_resid"}=$M_AMT_dt{"$ds_resid"}-$M_AMT;
				$sql_upt .=" update ctninfo..Train_book set Pay_amount=Pay_amount+$M_AMT,PP_method='$p_Pay_type' where Reservation_ID='$ds_resid' \n";
				$sql_upt .= " insert into ctninfo..Train_Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) 
					values('$ds_resid','F','$in{User_ID}','H',getdate()) \n ";
				$sql_upt .= " update ctninfo..Inc_book_detail set Ds_recv=Ds_recv+$M_AMT where  Res_ID ='$in{Reservation_ID}' and Serial_no=$ds_no[$j] \n";
				if (grep {$_ eq $user_type} keys %m_type){	##������ϡ�������������liangby@2006-12-11
				   ##д��������ѱ���Ʊ����Ϊ��
				   $sql_upt .=&account_reward("$ds_resid","F","$Corp_center","$in{User_ID}","$member_id","$user_type","$p_Pay_type","��Ʊ","$amt_total");
				}

			}
		}
	}
	$rmk_ms=5*$p+15; ##����ʱ��
	if ($in{recv_total} !=$left_total) {##Ƿ��
		if ($old_pro_id eq "12") {#	Ԥ�����ֵ	fanzy@2012-7-17
			print MessageBox("������ʾ","Ԥ�����ֵ��֧��Ƿ��");
			exit;
		}
		$sql_upt .=" insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) 
			values('$in{Reservation_ID}','G','$in{User_ID}','0',dateadd(ms,$rmk_ms,getdate())) \n";
	}else{
		if ($old_pro_id eq "12") {#	Ԥ�����ֵ	fanzy@2012-7-17
			if ($Corp_type ne "T") {exit;	}
			$sql="select Credit_total,Credit_used,Status,Op_type from ctninfo..Corp_credit where Corp_ID='$bk_corp' and Ticket_ID='$Corp_center' and History=0 ";
			my $Op_types="N";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						if ($row[3] eq "0" || $row[3] eq "3") {
							$Op_types="Y";
						}
					}
				}
			}
			
			if ($Op_types eq "N") {
				if (grep {$_ eq $usertype} keys %m_type) {
				}else{
					print MessageBox("������ʾ","�ͻ����� $bk_corp ��Ԥ����Ȩ��");
					exit;
				}
			}
			if ($bk_corp ne $Corp_center && $Op_types eq "Y") {##�ͻ�Ԥ����
				my $rmk="Ԥ�����ֵ��";
				## �޸���ʷ��¼
				$sql_upt .= "declare \@i_his integer \n";
				$sql_upt .= "select \@i_his=max(History)+1 from ctninfo..Corp_credit where Ticket_ID='$Corp_center' and Corp_ID='$bk_corp' \n";
				$sql_upt .= "update ctninfo..Corp_credit set History=\@i_his where Ticket_ID='$Corp_center' and Corp_ID='$bk_corp' and History=0 \n";
				## д���µ����Ѽ�¼
				$sql_upt .= "insert into ctninfo..Corp_credit(Corp_ID,Ticket_ID,History,Credit_total,Credit_used,Status,Mod_by,Mod_time,Inc_credit,Remark,Op_type,Pay_str,Pay_kemu,Pay_bank)
					select '$bk_corp','$Corp_center',0,Credit_total+$in{recv_total},0,Status,'$in{User_ID}',getdate(),$in{recv_total},'$rmk','0','$in{Reservation_ID}','$p_Pay_type','$p_Pay_type2' 
					from ctninfo..Corp_credit where Ticket_ID='$Corp_center' and Corp_ID='$bk_corp' and History=\@i_his \n";
				if ($old_other_fee !=0 ) {##�����  liangby@2012-12-28
					$sql_upt .= " select \@i_his=max(History)+1 from ctninfo..Corp_credit where Ticket_ID='$Corp_center' and Corp_ID='$bk_corp' 			
						update ctninfo..Corp_credit set History=\@i_his where Ticket_ID='$Corp_center' and Corp_ID='$bk_corp' and History=0 \n"; 
					$sql_upt .= "insert into ctninfo..Corp_credit(Corp_ID,Ticket_ID,History,Credit_total,Credit_used,Status,Mod_by,Mod_time,Inc_credit,Remark,Op_type,Pay_str,Pay_kemu,Pay_bank)
						select '$bk_corp','$Corp_center',0,Credit_total+(-1*$old_other_fee),Credit_used,'Y','$in{User_ID}',getdate(),-1*$old_other_fee,'Ԥ�����ֵ�۳������,$in{Reservation_ID}','0','$in{Reservation_ID}','$p_Pay_type','$p_Pay_type2'
						from ctninfo..Corp_credit where Ticket_ID='$Corp_center' and Corp_ID='$bk_corp' and History=\@i_his \n";
				}
				## �޸� Corp_info �Ķ�Ӧ���ݣ��Ա�ͻ����������ѯʹ��
				$sql_upt .= "update ctninfo..Corp_info set Credit_total=Credit_total+$in{recv_total} where Corp_ID='$bk_corp' \n";
			}elsif(grep {$_ eq $usertype} keys %m_type){##��ԱԤ�����ֵ liangby@2015-5-6
				my $rmk="Ԥ�����ֵ";
				if ($in{recv_total} <0) {##�˿�,����Ϊ��ֵ
					$rmk="Ԥ�����˿�";
				}
				$sql_upt .= "declare \@i_his integer
					select \@i_his=Isnull(max(History)+1,0) from ctninfo..User_credit where Sales_ID='$Corp_center' and User_ID='$user_id' 			
					update ctninfo..User_credit set History=\@i_his where Sales_ID='$Corp_center' and User_ID='$user_id' and History=0 \n";
			
				$sql_upt .= " if exists(select * from ctninfo..User_credit where Sales_ID='$Corp_center' and User_ID='$user_id' )
				  begin
					  insert into ctninfo..User_credit(User_ID,Sales_ID,History,Credit_total,Status,Mod_by,Mod_time,Inc_credit,
						Remark,Op_type,Pay_str,Op_str,Pay_kemu,Pay_bank)
					select '$user_id','$Corp_center',0,Credit_total+$in{recv_total},'Y','$in{User_ID}',getdate(),$in{recv_total},
						'$rmk','0','$in{Reservation_ID}','','$p_Pay_type','$p_Pay_type2'
					from ctninfo..User_credit where Sales_ID='$Corp_center' and User_ID='$user_id' and History=\@i_his 
				  end \n
				  else
				  begin
					 insert into ctninfo..User_credit(User_ID,Sales_ID,History,Credit_total,Status,Mod_by,Mod_time,Inc_credit,
						Remark,Op_type,Pay_str,Op_str,Pay_kemu,Pay_bank)
					  values('$user_id','$Corp_center',0,$in{recv_total},'Y','$in{User_ID}',getdate(),$in{recv_total},
						'$rmk','0','$in{Reservation_ID}','','$p_Pay_type','$p_Pay_type2')
				  end \n ";
				if ($old_other_fee !=0 ) {##�����  liangby@2012-12-28
					$sql_upt .= " select \@i_his=Isnull(max(History)+1,0) from ctninfo..User_credit where Sales_ID='$Corp_center' and User_ID='$user_id' 			
						update ctninfo..User_credit set History=\@i_his where Sales_ID='$Corp_center' and User_ID='$user_id' and History=0 \n";
					$sql_upt .=" insert into ctninfo..User_credit(User_ID,Sales_ID,History,Credit_total,Status,Mod_by,Mod_time,Inc_credit,
						Remark,Op_type,Pay_str,Op_str,Pay_kemu,Pay_bank)
					select '$user_id','$Corp_center',0,Credit_total+(-1*$old_other_fee),'Y','$in{User_ID}',getdate(),-1*$old_other_fee,
						'$rmk,�۳������','0','$in{Reservation_ID}','','$p_Pay_type','$p_Pay_type2'
					from ctninfo..User_credit where Sales_ID='$Corp_center' and User_ID='$user_id' and History=\@i_his  ";
				}
				$sql_upt .=" update ctninfo..User_info set Domicile=rtrim(str_replace(Domicile,'f',null)+'f') where User_ID='$user_id' and Corp_num='$Corp_center' and User_type='C' \n";
			}
		}
		
		$sql_upt .=" insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) 
			values('$in{Reservation_ID}','G','$in{User_ID}','H',dateadd(ms,$rmk_ms,getdate())) \n";
		if ($old_pro_id ne "10") {
			if (grep {$_ eq $usertype} keys %m_type){## N�����V�����A�������B��ʯ�� 
				##������Ÿ�����    liangby@2017-4-6
				my $sql_reward =&account_reward("$in{Reservation_ID}","G","$Corp_center","$in{User_ID}","$user_id","$usertype",$p_Pay_type,$pro_title,$Out_total);
				if ($sql_reward ne "") {
					$sql_upt .=" if (select Out_total+Isnull(Other_fee,0)-Recv_total
						from ctninfo..Inc_book where Res_ID='$in{Reservation_ID}')=0 \n BEGIN "; 
					$sql_upt .=$sql_reward;
					$sql_upt .=" END\n";
				}
				
			}
		}
		## ��ԱԤ���������Ƿ���֣����޸������������	
		$sql_upt .= "update ctninfo..User_info set Last_bk_time=getdate() where  User_ID='$user_id' and Corp_num='$Corp_center' \n";	
	}
	#print "<pre>$sql_upt";
#	my ($sms_pay,$sms_reward,$sms_total,$sms_pay)=();
#	my $Update = 0;
#	$db->ct_execute($sql_upt);
#	while($db->ct_results($restype) == CS_SUCCEED) {
#		if($restype==CS_CMD_DONE) {
#			next;
#		}elsif($restype==CS_COMPUTE_RESULT) {
#			next;
#		}elsif($restype==CS_CMD_FAIL) {
#			$Update = 0;		
#			next;
#		}elsif($restype==CS_CMD_SUCCEED) {
#			$Update = 1;			
#			next;
#		}
#		elsif($restype==CS_ROW_RESULT) {
#			while(@row = $db->ct_fetch) {
#				if (scalar(@row)==1 && $payment_rmk_tp{$sxk_id} ne "") {##������ۿ��¼
#					 $cp_sno{$sxk_id}=$row[0];
#				}else{
#					($sms_pay,$sms_reward,$sms_total,$sms_pay) = @row;
#					$sms_total = $sms_total-$sms_pay;
#				}
#			}
#		}	
#	}
#	if($Update eq '1') {
#		$db->ct_execute("Commit Transaction sql_insert");
#		#$db->ct_execute("Rollback Transaction sql_insert");
#		while($db->ct_results($restype) == CS_SUCCEED) {
#			if($restype==CS_ROW_RESULT) {
#				while(@row = $db->ct_fetch) {
#				}
#			}
#		}
#			return "<font color='blue'>$in{Reservation_ID}���������ɹ���</font></br>";
#	}
#	else{
#		$db->ct_execute("Rollback Transaction sql_insert");
#		while($db->ct_results($restype) == CS_SUCCEED) {
#			if($restype==CS_ROW_RESULT) {
#				while(@row = $db->ct_fetch) {
#				}
#			}
#		}
#		return "<font color='red'>$in{Reservation_ID}��������ʧ�ܣ�</font></br>";
#	}
	
}
## ������Ʒ�������Ӧ���б�    ilangby@2016-5-23
sub inc_account_sp{

	my %pay_method=&Get_pay_method("N","hash");
	my %kemu_hash = &get_kemu($Corp_center,"","hash","","");
	%pay_method=(%pay_method,%kemu_hash);
	print qq`<script language='javascript' >
	// ��ȡDOMԪ��,��ֹ&inc_account_sp�����ҳ����� jf on 2018/5/23
	function Fid(id){  
		return typeof(id) === "string"?document.getElementById(id):id;    
	}  
	function  inc_cash(resid){
		window.open('inc_account_do.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&History=$in{History}&Payfortype=2','PY_'+resid,'scrollbars,width=800,height=420,left=200,top=200');
	}
	function Show_book(resid){
		window.open('/cgishell/golden/admin/inc_goods/inc_view.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&History=$in{History}','V_'+resid,'scrollbars,width=540,height=320,left=200,top=200');
	}
	function show_his(resid){
		window.open('/cgishell/golden/admin/inc_goods/inc_history.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&History=$in{History}','P_'+resid,'scrollbars,width=420,height=300,left=200,top=200');
	}
	function Show_relate(resid){
		window.open('air_relate.pl\?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid,'R_'+resid,'scrollbars,width=360,height=280');
	}
	</script>`;
	if ($in{down_data} eq "Y") {
		$dw_hidden = "none";
	}else{
		$dw_hidden = "block";
	}
	print qq`<script type='text/javascript' src='/admin/js/tips/tips.js'></script>
		<form method=post name=book id="book" action='' style="display:$dw_hidden">
		<div class="airlines_list scroll_chaoc">
		<span id='printTitle'></span>
		<span id='printSpan'>
		<table width="100%" border="0" cellspacing="1" cellpadding="1" bgcolor="dadada" ><tbody>
		<tr bgcolor="#efefef">`;
	if (($in{Order_type} == 3 && ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3)) || ($in{Order_type} == 2 && ($in{Op} eq 0 || $in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4))){	
		print "<td height='30'><font color=blue>����</td>";	
	}else{
		print "<td height='30'></td>";	
	}
	if ($in{down_data} eq "Y") {
		## �½�Excel����
		my $root_path="d:/upload/";
		if (! -e $root_path) {#Ŀ¼������
			 mkdir($root_path,0002);
		}elsif(!-d $root_path){#�����ļ�������Ŀ¼
			 mkdir($root_path,0002);
		}
		my $r_path="d:/upload/report_file/";
		if (! -e $r_path) {#Ŀ¼������
			 mkdir($r_path,0002);
		}elsif(!-d $r_path){#�����ļ�������Ŀ¼
			 mkdir($r_path,0002);
		}
		my $path="d:/upload/report_file/$Corp_ID/";
		if (! -e $path) {#Ŀ¼������
			 mkdir($path,0002);
		}elsif(!-d $path){#�����ļ�������Ŀ¼
			 mkdir($path,0002);
		}
		my $ttime=$time;
		$ttime=~ s/\:*//g;
		my $ttoday=$today;
		$ttoday=~ s/\.*//g;
		my $context = new MD5;
		$context->reset();
		$context->add($year.$ttoday.$ttime.$Corp_ID."mfssdfdsfdfdsfde4423");
		my $md5_filename = $context->hexdigest;
		$BUF= $path.$md5_filename.".xls";
		$del_link="d:/www/Corp_extra/$Corp_ID/";
		$workbook;
		$workbook= Spreadsheet::WriteExcel::Big->new($BUF); 

		# �¼�һ�������� 
		$worksheet = $workbook->addworksheet("��Ƚ����");
		##���ݸ�ʽ
		$format1 = $workbook->addformat();
		## 9������
		$format1->set_size(9);
		$format1->set_color('black');
		$iRow=0;
		$iCol=0;
		$worksheet->write_string($iRow,$iCol,"������",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��Ӧ��",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��Ʒ����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��Ʒ����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"״̬",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"Ԥ��Ա",$format1);$iCol++;
		if ($in{Order_type} == 2 && $in{Op} eq 2){
			$worksheet->write_string($iRow,$iCol,"�������",$format1);$iCol++;
			$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol++;
		}
		$worksheet->write_string($iRow,$iCol,"������",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"�Ѹ����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"Ӧ�����",$format1);$iCol++;
		$iRow=1;
		$iCol=0;
	}
	print qq!
		<td height=19>������</td>
		<td>��Ӧ��</td>
		<td>��Ʒ����</td>
		<td>��Ʒ����</td>
		<td>״̬</td>
		<td>Ԥ��Ա</td>!;
	if ($in{Order_type} == 2 && $in{Op} eq 2){
		print qq!
		<td>�������</td>
		<td>�����</td>
		!;
	}
	print qq!
		<td align=right>������</td>
		<td align=right>�Ѹ����</td>
		<td align=right>Ӧ�����</td>!;
	if (($in{Order_type} == 2 && $in{Op} eq "0") || ($in{Order_type} == 3 && $in{Op} ne "1") ) {
		print qq!<td align=right>ʵ�����</td>!;
	}
	if($in{day_type} eq "D") {
		print "<td align=center>����</td>";
	}
	print "</tr></tbody>";
	if ($in{Op} eq "") {
		$in{Op}="0";
	}

	## ��ѯƱ֤��Դ
#	my @office_array = &get_office($Corp_office,"","array","A','H','T','V","","Y");
#	%office_name = ();
#	for (my $i = 0; $i < scalar(@office_array); $i++) {
#		if (($office_array[$i]{o_type} eq "A" && $office_array[$i]{type}=~/[YP]/) || $office_array[$i]{o_type}=~/[HTV]/) {	## ��Ʊ���⹺��ƽ̨��Ƶ��Ʊǩ֤
#			my $o_type="[��Ʊ]";
#			if ($office_array[$i]{o_type} eq "H") {	 $o_type="[�Ƶ�]";	}
#			elsif ($office_array[$i]{o_type} eq "T") {	 $o_type="[��Ʊ]";	}
#			elsif ($office_array[$i]{o_type} eq "V") {	 $o_type="[ǩ֤]";	}
#			
#		}
#	}
	$sp_corp_list="<option value='' >��ѡ��Ӧ��</option>";
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
				$sp_corp_list .=qq!<option value="$row[1]">$office_typename $row[2]</option>!;
			}
		}
	}
	$sql =" select distinct a.Res_ID,a.Inc_title,a.In_total,Isnull(a.Pay_total_sp,0),a.Book_status,
			rtrim(a.Sp_corp),a.Contract,a.Book_ID,c.Pro_name,a.Pro_id,convert(char(10),a.Settle_checkdate,102),a.Settle_checkman
		from ctninfo..Inc_book a,ctninfo..d_inc_pro c
		where a.Pro_id=c.Pro_id
			and a.Sales_ID='$Corp_center' 
			and c.Corp_ID in ('SKYECH','$Corp_center')
			and a.Book_status in ('P','S','H') 
			and a.Order_type=null
			and a.Pro_id not in(10,11,12,26,28) \n";#fanzy@2012-6-6	���ε� ����ȷ�ϵ����������
	if ($Corp_type ne "T") {#fanzy@2012-7-17	���ε� Ԥ�����ֵ��
		##�ӱ�������Ҫ��Ӫҵ��Ҳ��������Ԥ�����ֵ��   liangby@2015-3-5
		if ($Corp_center eq "SJW121" && $Is_delivery eq "Y") {
			$sql .=" and a.Send_corp='$Corp_ID' \n";
		}else{
			$sql .=" and a.Pro_id<>12\n";
		}
		
	}
	if ($in{Res_ID} ne "") {
		$sql .= "and a.Res_ID='$in{Res_ID}' \n";
	}
	else{
		if ($in{Guest_name} ne "") {	$sql .=" and a.Contract = '$in{Guest_name}' \n";	}
		if ($in{Sp_corp_q} ne "") {	$sql .=" and a.Sp_corp = '$in{Sp_corp_q}' \n";	}
		if ($in{user_book} ne "") { $sql .= " and a.Book_ID = '$in{user_book}' \n";	}
		if ($in{Corp_ID} ne "") { $sql .= " and a.Corp_ID = '$in{Corp_ID}' \n";}
		if ($in{pid} ne "") { $sql .= " and a.Pro_id =$in{pid} \n";}
		if ($in{date_type} eq "T" || $in{date_type} eq "B" || $in{date_type} eq "") {
		
			$sql .= "and a.Ticket_date >='$Depart_date' 
				and a.Ticket_date <'$in{End_date}' \n";
			
		}
		elsif($in{date_type} eq "S"){
			$sql .= "and a.S_date >='$Depart_date' 
				and a.S_date <'$in{End_date}' \n";
		}
		else{
			$sql .= "and a.Book_time >='$Depart_date' 
				and a.Book_time <'$in{End_date}' \n";
		}
		
		if ($in{Op} eq "0") {	## ������
			if($logo_path =~ /f/ && $logo_path !~ /g/){## ֻ����ҵ�������
				$sql .=" and Isnull(a.Pay_total_sp,0) != a.In_total and a.Check_status&1=1 and a.Check_status&3<>3 \n";
			}elsif($logo_path !~ /f/ && $logo_path =~ /g/){## ֻ���ò������
				$sql .=" and Isnull(a.Pay_total_sp,0) != a.In_total and a.Check_status&2=2 and a.Check_status&3<>3\n";
			}elsif($logo_path =~ /f/ && $logo_path =~ /g/){## ������
				$sql .=" and Isnull(a.Pay_total_sp,0) != a.In_total and a.Check_status&3=3 \n";
			}else{ ## ��������
				$sql .=" and Isnull(a.Pay_total_sp,0) != a.In_total \n";
			}
		}elsif ($in{Order_type} == 3 && $in{Op} eq "1"){	## �Ѹ���
			$sql .=" and a.Pay_total_sp = a.In_total \n";
		}elsif ($in{Order_type} == 2 && $in{Op} eq "1"){	## �Ѹ���δ���
			$sql .=" and a.Pay_total_sp = a.In_total and a.Settle_checkdate = null and a.Settle_checkman = null \n";
		}elsif ($in{Order_type} == 2 && $in{Op} eq "2"){	## �����
			$sql .=" and a.Pay_total_sp = a.In_total and a.Settle_checkdate != null and a.Settle_checkman != null \n";
		}elsif ($in{Order_type} == 2 && $in{Op} eq "3"){	## ҵ�������
			$sql .=" and Isnull(a.Pay_total_sp,0) != a.In_total and a.Check_status=null \n";
		}elsif ($in{Order_type} == 2 && $in{Op} eq "4"){	## �������
			if($logo_path =~ /f/ ){## ���������ҵ�������	
				$sql .=" and Isnull(a.Pay_total_sp,0) != a.In_total and a.Check_status&1=1 and a.Check_status&3<>3\n";
			}else{
				$sql .=" and Isnull(a.Pay_total_sp,0) != a.In_total and a.Check_status=null \n";	
			}
		}
		$sql .= " order by a.Ticket_date \n";
	}
	#print "<pre>$sql";
	my ($Out_total,$Recv_total,$Left_total,$i)=(0,0,0,0);
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row=$db->ct_fetch)	{
				my $left_price=sprintf("%.2f",$row[2]-$row[3]);
				my $b_st_str;
				if($left_price !=0 ){##�������ܼƲ���ʱ��״̬  zhangl@2011-10-21
					if ($row[3] ==0 && $row[2] !=0) {
						$b_st_str = "δ����";
					}else{
						$b_st_str = "���ָ���";
					}
				}else{
					$b_st_str=&get_book_status($row[4]);
				}
				$sp_corpid=$row[5];
				$Out_total +=$row[3];
				$Recv_total +=$row[4];
				$Left_total +=$left_price;
				my $op=qq!<a href="javascript:inc_cash('$row[0]');" title="�鿴�����¼" >$row[0]</a>!;
			
		
				$a_dis = "";
				if ($left_price ==0) {
					$a_dis="disabled";
				}
				print qq`<tr class="odd" onmouseout="this.style.background='#ffffff'" onmouseover="this.style.background='#fef6d5'">`;
				if (($in{Order_type} == 3 && ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3)) || ($in{Order_type} == 2 && ($in{Op} eq 0 || $in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4))) {##������������Ʒ��ˡ�ҵ������ˡ�������ˣ�����ǰ������ jf@2018/5/22
					print qq!<td width=30>!;
					if ($in{Order_type} == 2 && ($in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4)){
						print qq!<input  type="checkbox" name=cb_$i id="cb_$i" value="$row[0]" onclick="ck_kbres($i);" class="radio_publish">!;
					}else{
						print qq!<input $a_dis type="checkbox" name=cb_$i id="cb_$i" value="$row[0]" onclick="ck_kbres($i);statistics();" class="radio_publish">!;
					}
					print qq!
						<input type=hidden name=Reservation_ID_$i id="resid_$i" value="$row[0]" /><input type=hidden name=old_left_total_$i value="$left_price" />
						<input type=hidden name=old_recv_total_$i id="old_recv_total_$i" value="$left_price" />
						<input type=hidden name=old_proid_$i id="old_proid_$i" value="$row[9]" />
						<input type=hidden name=old_spcorp_$i id="old_spcorp_$i" value="$row[5]" />
						</td>!;
				}else { print "<td></td>"; }
				
				if ($in{down_data} eq "Y") {
					$op =~ s/<[^>]*>//g;
					$iCol=0;
					$worksheet->write_string($iRow,$iCol,$op,$format1);$iCol++;
					$worksheet->write_string($iRow,$iCol,$office_name{$row[5]},$format1);$iCol++;
					$worksheet->write_string($iRow,$iCol,$row[8],$format1);$iCol++;
					$worksheet->write_string($iRow,$iCol,$row[1],$format1);$iCol++;
					$worksheet->write_string($iRow,$iCol,$b_st_str,$format1);$iCol++;
					$worksheet->write_string($iRow,$iCol,$row[7],$format1);$iCol++;
					if ($in{Order_type} == 2 && $in{Op} eq 2){
						$worksheet->write_string($iRow,$iCol,$row[10],$format1);$iCol++;
						$worksheet->write_string($iRow,$iCol,$row[11],$format1);$iCol++;
					}
					$worksheet->write_number($iRow,$iCol,$row[2],$format1);$iCol++;
					$worksheet->write_number($iRow,$iCol,$row[3],$format1);$iCol++;
					$worksheet->write_number($iRow,$iCol,$left_price,$format1);$iCol++;
					$iRow++;
				}

				print qq!<td height=20>$op</td>
					<td>$office_name{$row[5]}</td>
					<td>$row[8]</td>
					<td><a href="javascript:Show_book('$row[0]');" >$row[1]</a></td>
					<td><a href="javascript:show_his('$row[0]');" title="������¼">$b_st_str</a></td>
					<td>$row[7]</td>!;
				if ($in{Order_type} == 2 && $in{Op} eq 2){
					print qq!<td>$row[10]</td>
					<td>$row[11]</td>!;
				}
				print qq!
					<td align=right >$row[2]</td>
					<td align=right >$row[3]</td>
					<td align=right >$left_price</td>!;
				if (($in{Order_type} == 3 && ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3)) || ($in{Order_type} == 2 && $in{Op} eq 0 )) {
					print qq!<td align=right><input type=text id="recv_total_$i" name="recv_total_$i" value="$left_price" class="input_txt" style='color:blue;width:45px;' onblur="statistics();"/></td>!;
				}
				print qq!
				</tr>!;
				$i++;
			}
		}
	}

	$Out_total=sprintf("%.2f",$Out_total);
	$Recv_total=sprintf("%.2f",$Recv_total);
	$Left_total=sprintf("%.2f",$Left_total);
	if ($in{Order_type} == 2 && $in{Op} eq 2){
		$colspan=9
	}else{
		$colspan=7
	}
	print qq!<tr align=right bgcolor="#ffffff"><td colspan=$colspan height=21>�ϼƣ�</td>
	<td>$Out_total</td>
	<td><font color=blue>$Recv_total</font></td>
	<td>$Left_total</td>!;
	if (($in{Order_type} == 2 && $in{Op} eq "0" ) || ($in{Order_type} == 3 && $in{Op} ne "1")) {
		print qq!<td>&nbsp;</td>!;
	}
	
	print qq!</tr></table></span></div>
	<div class="clear"></div>!;

	if ($i > 0 && (($in{Order_type} == 3 && ($in{Op} eq 0 || $in{Op} eq 2 || $in{Op} eq 3)) || ($in{Order_type} == 2 && ($in{Op} eq 0 || $in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4)))){#��������������������Ʒ��ˡ�ҵ������ˡ�������ˣ�����ǰ������ jf@2018/5/22
		if ($in{Order_type} == 2 && ($in{Op} eq "1" || $in{Op} eq "3" || $in{Op} eq "4" )) {
	
		}else{		
			@tmp_array_list = ();
			##ԭ�տʽ����Ϣ  ,��ʾ������ϸʱ�õ���ǰ��������ʽ
			$sql = "select rtrim(Pay_method),Pay_name,Is_netpay,Is_show,Is_payed,Corp_ID,Pay_pic from ctninfo..d_paymethod 
				where  Corp_ID in ('SKYECH','$Corp_center') 
				order by Order_seq,Is_netpay ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT) {
					while(@row = $db->ct_fetch) {
						if ($Pay_version ne "1") {
							if ($row[3] eq "Y" && $row[2] eq "N" && $row[4] eq "Y") {
								push(@array_list, {Corp_ID   => "$row[5]",
									Type_ID => "$row[0]",
									Type_name  => "$row[1]",
									Pic => "$row[6]",
									Pid => "$row[0]",
									Parent => "",
								});
							}
						}
					}
				}
			}
			#if ($Pay_version eq "1") {
				##��ȡ��ƿ�Ŀ����Ϣ��ϣ��  liangby@2010-12-11
				%kemu_hash = &get_kemu($Corp_center,"","hash2","3","","","assist","N");
				## ��ƿ�Ŀ����
				@array_list = &get_kemu($Corp_center,"","array",3,"Y");
			#}
			## �����Ŀ�б�
			my $ass_ids;
			for (my $i = 0; $i < scalar(@array_list); $i++) {
				if ($array_list[$i]{Type_ID} eq $array_list[$i]{Pid}) {		$array_list[$i]{Pid} = '';	}
				my $listitem = qq`['$array_list[$i]{Corp_ID}', '$array_list[$i]{Type_ID}', '$array_list[$i]{Type_name}', '$array_list[$i]{Pid}','0']`;
				push(@tmp_array_list, $listitem);
				if ($array_list[$i]{Pid} ne "") {
					$ass_ids .= "','$array_list[$i]{Pid}";
				}
			}
			## ���������б�
			if ($ass_ids ne "" && $Pay_version == 1) {
				my @bank=&get_kemu($Corp_center,"","array","1","Y","N","assist");	
				for (my $i = 0; $i < scalar(@bank); $i++) {
					my $listitem = qq`['$bank[$i]{Corp_ID}', '$bank[$i]{Type_ID}', '$bank[$i]{Type_name}', '$bank[$i]{Parent}','1']`;
					push(@tmp_array_list, $listitem);
					$bank_name{$bank[$i]{Type_ID}}=$bank[$i]{Type_name};
				}
			}
		}
		print qq`
		<div class="operating" >
		<div class="operating_button">
		<div class="" style="position:absolute;margin-top:10px;right:40px;z-index:2;">
			<label><input type="checkbox" name="cb" id="cb" onclick="ck_all();" class="radio_publish">ѡ��ȫ��</label>`;
		if ($in{Order_type} == 2 && ($in{Op} eq "1" || $in{Op} eq "3" || $in{Op} eq "4" )){
			my $disabled=""; 
			if ( $in{Op} eq "3" && (&Binary_switch($Function_ACL{CWFK},0,'A')==0)){
				$disabled=" disabled=disabled";
			}
			if ( $in{Op} eq "4" && (&Binary_switch($Function_ACL{CWFK},1,'A')==0)){
				$disabled=" disabled=disabled";
			}
			print qq`<input id="btn_check" type=button value="���" class="btn30" onclick='button_check()' $disabled>`;
		}
		print qq`
		</div>
		<div>
			<font color=red>��ʾ���հ׵�ֻ�ܵ����������޷���������һ����������</font>
		</div>`;
		if ($in{Order_type} == 2 && ($in{Op} eq "1" || $in{Op} eq "3" || $in{Op} eq "4" )) {
		}else{
			print qq`
			<table width="100%" border="0" cellspacing="0" cellpadding="6">
			<tbody>
			<tr>
				<td>
					<table width="100%" border="0" cellspacing="0" cellpadding="6">
						<tbody>
							<tr>
								<td width="180">
									<label id="More_pay_mod"><nobr>
										<input name="" type="button" class="upload diaod_button" value="��Ӹ��ʽ" onclick="More_pay('add');"/>&nbsp;&nbsp;
										<input name="" type="button" class="save_ad diaod_button" value="���ٸ��ʽ" onclick="More_pay('del');"/></nobr>
									</label>
								</td>
								<td>
									&nbsp;ѡ�ж�����ʵ��&nbsp;<input name="Rec_tol" id="Rec_tol" type="text" class="input_txt input_txt70" style='color:blue' value="$Recv_total" readonly="" />
									<b class="red">δ���㣺<input name="Left_total" id="Left_total" type="text" class="input_txt input_txt70" style='color:red' value="$Left_total" readonly="" /><input type=hidden name=Total value='$Left_total'></b>
									&nbsp;&nbsp;<input name="bt_ok" id="bt_ok" type="button" class="again button_sizegy " onclick='button_onclick()' value="ȷ���ύ" />
									<input name="bt_no" id="bt_no" type="button" style="display:none" class="again button_sizegy " onclick='refuse_fk();' value="�ܾ�����" />
									<input name="" type="reset" class="again button_sizegy " value="����" />
								</td>
							</tr>
						</tbody>
					</table>
				</td>
			</tr>`;
			
			my $paymaxnum=30;#�տʽ�������3��
			for (my $p=0;$p<$paymaxnum ;$p++) {
				my $display=($p==0)?"":"display:none;";
				my $pp=($p==0)?"":"_$p";
				print qq`
				<tr id="paymore$pp" style="$display">
					<td>
						<table border=0 width=100% cellspacing=0 cellpadding=1 border=0 bgcolor=efefef style="border-bottom-color:#ddd;border-bottom-width:1px;border-bottom-style:dashed;">
							<tr>
								<td height=20>
									<label>���ʽ��<select id="list1$pp" name="Pay_type$pp" class="input_txt_select input_txtgy" style='width:130pt;' onchange="if('$Pay_version'=='1'){changelist('list1', 'list2','$p');}">$pay_list</select></label>
									<label>ƾ ֤ �ţ�<input type=text value='' id='pingzheng$pp' name='pingzheng$pp' style='width:100px;position:relative;z-index:10;' class="input_txt input_txt70"></label>
									<label>ʵ����<input type=text id="Pay_Rec_tol$pp" name="Pay_Rec_tol$pp" class="input_txt input_txt70" style='color:blue' value=0></label>
									<label>��Ӧ�̣�<select id="sp_corp$pp" name="sp_corp$pp" class="input_txt_select input_txtgy" style='width:130pt;' >$sp_corp_list</select></label>
									<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span id="sp_acountinfo$pp"></span>
							</td>
							</tr>
							<tr>
								<td height=20>
									<label id='list2_lb$pp'>������Ŀ��<select id="list2$pp" name='Pay_type2$pp' class="input_txt_select input_txtgy" style='width:130pt;'></select></label>
									<label id='list3$pp'>���ײο��ţ�<input type="text" id="ReferNo$pp" name="ReferNo$pp" maxlength=16 class="input_txt input_txt70" value="">
											�����У�<input type="text" id="BankName$pp" name="BankName$pp" maxlength=8 class="input_txt input_txt70" value="">
											�������ڣ�<input type=text id="ReOp_date$pp" name="ReOp_date$pp" class="input_txt input_txt70" readonly maxlength=10 value='' onclick="event.cancelBubble=true;ShowCalendar(document.getElementById('ReOp_date$pp'),document.getElementById('ReOp_date$pp'),null,0,330)">
											���ź�4λ��<input type="text" id="BankCardNo$pp" name="BankCardNo$pp" class="input_txt input_txt70" maxlength=4 value="">
									</label>
								</td>
							</tr>
						</table>
					</td>
				</tr>`;
			}
			print qq`
			<input type='hidden' name='pay_method_num' id='pay_method_num' value='1'/>
			<input type='hidden' name='pay_method_maxnum' id='pay_method_maxnum' value='$paymaxnum'/>
			</tbody></table></div>`;
		}
		print qq`
		<script language='javascript'>
			function ck_all(){
			if ( Fid('t_num').value == 0 ) return; 
				if (Fid('cb').checked) {
					for (var j=0; j < Fid('t_num').value; j++){
						if (Fid("old_proid_"+j).value!="29" ) {
							Fid('cb_'+j).checked = true; 
						}
					}
				}else{
					for (var j=0; j < Fid('t_num').value; j++){
						Fid('cb_'+j).checked = false;
					}
				}
				if ($in{Order_type} == 2 && ($in{Op} == 1 || $in{Op} == 3 || $in{Op} == 4)){
				
				}else{
					statistics();
				}
			}
			function statistics(){
				var Paid = 0;//ʵ��
				var Settlement =0;//δ����
				for (var j=0; j < Fid('t_num').value; j++){	
					if(Fid('cb_'+j).checked){
						Paid += parseFloat(Fid('recv_total_'+j).value);
					}
					Settlement += parseFloat(Fid('old_recv_total_'+j).value);
				}
				Settlement=Settlement-Paid;
				Paid=Round(Paid+0.000001,2)
				if (Fid('Rec_tol')){
					Fid('Rec_tol').value=Paid;
				}
				if (Fid('Left_total')){
					Fid('Left_total').value=Settlement;
				}
				if (Fid('pay_method_num').value=='1') {
					Fid('Pay_Rec_tol').value = Fid('Rec_tol').value;
				}
			}
			function ck_kbres(k){//�հ׵�ֻ�ܵ�������,���ܺ�����������һ�𸶿�
				var other_num=0
				var kbres_num=0;
			  
				for (var j=0; j < Fid('t_num').value; j++){	
					if(Fid("cb_"+j).checked && j !=k){
						if (Fid("old_proid_"+j).value=="29") {
							kbres_num++;
						}else{
							other_num++;
						}
					}
				}
				
				if(Fid("cb_"+k).checked){
					if (Fid("old_proid_"+k).value=="29" ) {
						for (var j=0; j < Fid('t_num').value; j++){	
							if(j !=k){
								Fid("cb_"+j).checked=false;
							}
						}
						if ($in{Order_type} == 2 &&( $in{Op} == 1|| $in{Op} == 3||$in{Op} == 4)){
				
						}else{
							clear_info();
							get_res_spcorp(Fid("resid_"+k).value);
							Fid("bt_no").style.display="";
							Fid("refuse_tab").style.display="";
						}
					}else{
						if (kbres_num>0) {
							Fid("cb_"+k).checked=false;
							if (Fid("bt_no")){
								Fid("bt_no").style.display="none";
							}
							if (Fid("refuse_tab")){
								Fid("refuse_tab").style.display="none";
							}
						}else{
							if ($in{Order_type} == 2 &&( $in{Op} == 1|| $in{Op} == 3||$in{Op} == 4)){
				
							}else{
								clear_info();
							}
							if (Fid("bt_no")){
								Fid("bt_no").style.display="none";
							}
							if (Fid("refuse_tab")){
								Fid("refuse_tab").style.display="none";
							}
							
						}
						if (Fid("old_proid_"+k).value=="27" ) {
							var sp_corp=Fid("old_spcorp_"+k).value;
							var pp="";
							var sp_corp_obj=Fid('sp_corp'+pp);
							if(sp_corp_obj){
								for (var j=0; j<sp_corp_obj.options.length;j++) {
									if (sp_corp_obj.options[j].value==sp_corp) {
										sp_corp_obj.options.selectedIndex=j;
									}
								}
							}
						}
					}
				}
			}
			function clear_info(){
				if (Fid('pay_method_maxnum')) {
					for (var p=0;p<parseInt(Fid('pay_method_maxnum').value,10) ;p++) {
						var pp='_'+p;
						if (p=='0') {
							pp='';
						}
						Fid('sp_acountinfo'+pp).innerHTML="";
						
					}
				}
			}
			function button_onclick(){
				var recordNumber=0;
				for (var i=0; i<Fid('t_num').value;i++){
					if(Fid('cb_'+i).checked==true){
						recordNumber++;
					}
				}
				if(recordNumber==0){
					alert('����ѡ�񶩵��ٽ��в�����');
					return false;
				}
				var num=parseInt(Fid('pay_method_num').value,10);
				var Pay_Rec_tol=0;
				var Pay_Recv_Mark='';
				for (var p=0;p<num ;p++) {
					var pp='_'+p;
					if (p=='0') {
						pp='';
					}
					var Pay_Rec_tol_p=Fid("Pay_Rec_tol"+pp);
					if(isNaN(Pay_Rec_tol_p.value)){ 
						alert('���ʽ��ʵ�������������֣�');
						Pay_Rec_tol_p.focus(); 
						return false; 
					}
					var Pay_Recv_Marks='';
					if (parseInt(Pay_Rec_tol_p.value,10)<0) {
						Pay_Recv_Marks='-1';
					}else{
						Pay_Recv_Marks='1';
					}
					if (Pay_Recv_Mark=='') {
						Pay_Recv_Mark=Pay_Recv_Marks;
					}
					if (Pay_Recv_Mark!=Pay_Recv_Marks) {
						alert('���ʽ��ʵ�������ͳһ������');
						Pay_Rec_tol_p.focus(); 
						return false; 
					}
					Pay_Rec_tol=Pay_Rec_tol+Round(Pay_Rec_tol_p.value,2);
					if (Fid("sp_corp"+pp).value=="") {
						alert("��ѡ��Ӧ��");
						return false;
					}
				}
				Pay_Rec_tol=Round(Pay_Rec_tol+0.000001,2);
				if (Pay_Rec_tol!=Fid('Rec_tol').value) {
					alert('���ʽ��ʵ�ս��֮��'+Pay_Rec_tol+'������ѡ�ж�������ʵ���ϼ�'+Fid('Rec_tol').value+'��');
					Fid('Pay_Rec_tol').focus(); 
					return false; 
				}
				Fid("bt_ok").disabled=true;
				Fid("book").submit();
			}
			function Round(a_Num , a_Bit)  {
				return( Math.round(a_Num * Math.pow (10 , a_Bit)) / Math.pow(10 , a_Bit))  ;
			}

			//�ܾ�����
			function refuse_fk(){
				Fid('refuse_pay').value="Y";
				Fid("book").submit();
			}
			function button_check(){
				var recordNumber=0;
				for (var i=0; i<Fid('t_num').value;i++){
					if(Fid('cb_'+i).checked==true){
						recordNumber++;
					}
				}
				if(recordNumber==0){
					alert('����ѡ�񶩵��ٽ��в�����');
					return false;
				}
				if(Fid("btn_check")){
					Fid("btn_check").disabled=true;
				}
				Fid("book").submit();
			}
		</script>`;
		## ������Ŀ����
		my $array_list = join(",\n", @tmp_array_list);
		##���Ҫ�޸ĸ�JS,��ɰ���տʽ   liangby@2010-12-23
		print qq`
		<script type="text/javascript">
			var payhash=[];
			var datalist = [$array_list];
			function More_pay(type){
				var maxnum=parseInt(Fid('pay_method_maxnum').value,10);
				var num=parseInt(Fid('pay_method_num').value,10);
				if (type=='add') {
					if (num>=maxnum) {
						return;
					}
					num++;
					Fid('pay_method_num').value=num;
				}else if(type=='del'){
					if (num<=1) {
						return;
					}
					num--;
					Fid('pay_method_num').value=num;
				}
				for (var p=0;p<maxnum ;p++) {
					var pp='_'+p;
					if (p=='0') {
						pp='';
					}
					var paymore=Fid('paymore'+pp);
					if (p<num) {
						paymore.style.display = "";
					}else{
						paymore.style.display = "none";
					}
				}
				if (num==1) {
					Fid('Pay_Rec_tol').value =Fid('Rec_tol').value;
				}
			}
			function createlist(list, pid,payid) {
				var ppayid='_'+payid;
				if (payid=='0') {
					ppayid='';
				}
				removeAll(list);
				if (list.id=="list2"+ppayid) {
					list.style.display ='';
					Fid("list2_lb"+ppayid).style.display='';
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
					if (pid == '' && datalist[i][4] != '0')	{	// ���ʽ
						continue;
					}
					if (array_exists(exists_value, datalist[i][1]))	// �����ظ��������б�
					{
						continue;
					}
					list[list.options.length] = new Option(datalist[i][2], datalist[i][1]);
					exists_value.push(datalist[i][1]);	// д����������������ж��ظ�
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
					if (list.id=="list2"+ppayid) {
						list.style.display ='none';
						Fid("list2_lb"+ppayid).style.display='none';
					}
				}
				if (pid=='1003.01.01' || pid=='1003.01.02') {//POS�����������п��ŵ�fanzy2012-6-27
					Fid("list3"+ppayid).style.display='';
				}else {
					Fid("list3"+ppayid).style.display='none';
				}
			}
			function changelist(src, obj,payid) {
				var ppayid='_'+payid;
				if (payid=='0') {
					ppayid='';
				}
				src = Fid(src+ppayid);
				obj = Fid(obj+ppayid);
				var srcvalue = '';
				if (Fid(src+ppayid)){
					srcvalue = src.options[src.options.selectedIndex].value;
				}
				createlist(obj, srcvalue,payid);
			}
			var removeAll = function(obj){
				obj.options.length = 0;
			}
			//�������Ԫ���Ƿ����
			function array_exists(arr, item){
				for (var n = 0; n < arr.length; n++)
				if (item == arr[n]) return true;
				return false;
			}
			function change_cmt(selectobj, inputobj, inputobj1){
				var sIndex=Fid(selectobj).selectedIndex;
				var prod = Fid(selectobj).options[sIndex].text;
				var prods = Fid(selectobj).options[sIndex].value;
				Fid(inputobj).value = prod;
				var arr=[];arr=prods.split("#");
				Fid(inputobj1).innerHTML = arr[1];
			}
			var val=Fid("pay_method_maxnum")?Fid("pay_method_maxnum").value:0;
			for (var i=0;i<parseInt(val,10) ;i++) {
				changelist('', 'list1',i);
				changelist("list1","list2",i);
			}
		</script>
		`;
	}
	print qq!
	<input type=hidden name=User_ID value="$in{User_ID}" />
	<input type=hidden name=Serial_no value="$in{Serial_no}" />
	<input type=hidden name=Order_type value="$in{Order_type}" />
	<input type=hidden name=Depart_date value="$Depart_date" />
	<input type=hidden name=End_date value="$End_date" />
	<input type=hidden name=Op value="$in{Op}" />
	<input type=hidden name=Do_act value="W" />
	<input type=hidden name=Corp_ID value="$in{Corp_ID}" />
	<input type=hidden name=user_book value="$in{user_book}" />
	<input type=hidden name=Start value="1" />
	<input type=hidden name=air_type value="$in{air_type}" />
	<input type=hidden name=Sender value="$in{Sender}" />
	<input type=hidden name=History value="$in{History}" />
	<input type=hidden name=pay_obj value="$in{pay_obj}" />
	<input type=hidden name=Send_corp value="$in{Send_corp}" />
	<input type=hidden id="t_num" name=t_num value=$i />
	<input type=hidden name=Remark value="�����������" />
	<input type=hidden name=Payfortype value="2" />
	<input type=hidden id="pay_attach" name=pay_attach value="" />
	<input type=hidden id="refuse_pay" name=refuse_pay value="" />
	</form>!;

	if ($in{Order_type} == 2 && ($in{Op} eq "1" || $in{Op} eq "2" || $in{Op} eq "3" || $in{Op} eq "4")) {
	
	}else{
		print qq`
		<table border=0 cellpadding=0 cellspacing=0  style="display:$dw_hidden">
			<tr>
				<td width=70>�������</td>
				<td>
					<form name="Upload" action="http://$G_SERVER/cgishell/golden/admin/message/upload_attach.pl" method="post" enctype="multipart/form-data" target="UploadWindow" class="file_box_s1" id="fileup">
						<input type="file" name="NewFile" class="file" id="NewFile" size="28" onchange="document.getElementById('return_error').innerHTML='�ϴ���,���Ժ�...';this.form.submit();" />
						<span id="return_error"></span>
						<input type=hidden name="User_ID" value="$in{User_ID}">
						<input type=hidden name="Serial_no" value="$in{Serial_no}">
						<input type=hidden name="Type" value="attach">
						<input type=hidden name="current_domain" id="current_domain" value="$ENV{SERVER_NAME}">
					</form>
					<span id='fileshow'></span>&nbsp;&nbsp;&nbsp;<span id='fileshow1' style="color:#B50729"></span>
				</td>
			</tr>
		</table>
		<iframe name="UploadWindow" style="display:none;" src=""><\/iframe>
		<script language="javascript" src="/admin/js/ajax/jquery-1.3.2.min.js"></script>
		<script type="text/javascript">
			Fid('current_domain').value=document.domain;
		
			function OnUploadCompleted( errorNumber, fileUrl, fileName, customMsg){
				Fid('fileshow1').innerHTML="";
				var return_error=Fid('return_error');
				Fid('NewFile').outerHTML=Fid('NewFile').outerHTML.replace(/(value=\\").+\\"/i,"\$1\\"");
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
						return_error.innerHTML='<font color="red">��Ч���ļ�����</font>';
						return ;
					case 203 :
						return_error.innerHTML='<font color="red">����������ʧ��,������û��Ȩ��.</font>';
						return ;
					case 500 :
						return_error.innerHTML='<font color="red">����������ʧ��</font>';
						break ;
					default :
						return_error.innerHTML='<font color="red">�ϴ��ļ�����: '+errorNumber+'</font>';
						return ;
				}
				Fid('pay_attach').value=fileUrl;
				showfile('sh');
			}
			function showfile(type){
				if (type=='sh') {
					var file=Fid('pay_attach').value;
					if (file=="") {
						sh('fileup');
						hd('fileshow');
					}else{
						if(file.indexOf('\/') > -1){	//���ļ�������wwwĿ¼��
							flie_name=file.substring(file.lastIndexOf('\/')+1);
							file_type1="old";
						}else{	//���ļ�������uploadĿ¼��
							flie_name=file;
							file_type1="new";
						}
						var fire_route="http://$G_SERVER/cgishell/golden/admin/report/echo_down.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&file_type=inc_pay&file_type1="+file_type1+"&file_name="+flie_name;
						Fid('fileshow').innerHTML='<a href="'+fire_route+'" target="_blank" style="text-decoration:underline;color:blue;">'+file+'</a>��<a href="javascript:delfile();"><font color="red">ɾ��</font></a>';
						hd('fileup');
						sh('fileshow');
					}
				}else{
					hd('fileup');
				}
			}
			function delfile(){
				var file=Fid('pay_attach').value;
				\$.getJSON("http://$G_SERVER/cgishell/golden/admin/message/upload_attach.pl?callback=?", {User_ID:"$in{User_ID}",Serial_no:"$in{Serial_no}",Type:"delfile",keyword:file,file_type:'inc_pay'},
				function(data) {
					var catalog=data['delfile'];
					if (catalog=="ɾ���ɹ�") {
						Fid('fileshow1').innerHTML="";
						Fid('pay_attach').value="";
					}else{
						Fid('fileshow1').innerHTML="*"+catalog;
					}
					showfile('sh');
					return;
				});
			}
			function sh(strtype)	{
				if (Fid('strtype')) {
					Fid('strtype').style.display = "";
				}
			}
			function hd(strtype)	{
				if (Fid('strtype')) {
					Fid('strtype').style.display = "none";
				}
			}
		</script>`;
		print qq`
		<table id="refuse_tab" style="display:none">
			<tr>
				<td>�ܸ���ע��</td>
				<td>
					<textarea name="refuse_remark" id="refuse_remark" rows="3" maxlength="128" wrap="hard" style="width: 580px;"></textarea>
				</td>
			</tr>	
		</table>`;		
		print qq`<script type="text/javascript" src="/admin/js/ajax/jquery-1.3.2.min.js" charset="gb2312"></script>
		  <div class="wrapper" id="auto_process"></div>`;
		print qq`<script language=javascript>
		function get_res_spcorp(resid){
			for (var p=1;p<parseInt(Fid('pay_method_maxnum').value,10) ;p++) {
				More_pay('del');
			}
			Fid('auto_process').innerHTML='���ڻ�ȡ������Ӧ����Ϣ�����Ժ򡭡���';
			\$.ajax({type:"POST",dataType:'jsonp',timeout:'120000',url:"/cgishell/golden/admin/airline/res/air_account_fk.pl?callback=?",
				data:{User_ID:'$in{User_ID}',Serial_no:'$in{Serial_no}',Res_ID:resid,data_type:'json'},
				success:function(data){
						 
					if (data['status']=='OK') {
						Fid('auto_process').innerHTML = '';
						if (data['sp_corpinfo'][0]) {
							var html_str="";
							for (var i=0;i<data['sp_corpinfo'].length;i++){
								var sp_corp=data['sp_corpinfo'][i]['sp_corp'];
								var account_info=data['sp_corpinfo'][i]['account_info'];
								var sp_amount=data['sp_corpinfo'][i]['sp_amount'];
								var pp='_'+i;
								if (i=='0') {
									pp='';
								}
								var num=parseInt(Fid('pay_method_num').value,10);
								if (i>0 && num<data['sp_corpinfo'].length) {
									More_pay('add');
								}
								var sp_corp_obj=Fid('sp_corp'+pp);
								for (var j=0; j<sp_corp_obj.options.length;j++) {
									if (sp_corp_obj.options[j].value==sp_corp) {			
										sp_corp_obj.options.selectedIndex=j;
									}
								}
								Fid('Pay_Rec_tol'+pp).value=sp_amount;
								Fid('sp_acountinfo'+pp).innerHTML="<font color=red>"+account_info+"</font>";
									
							}
								
						}
						var refuse_remark=data['refuse_remark'];	//�հ׵��ܾ����ע
						Fid("refuse_remark").value=refuse_remark;
					}
					else{
						Fid('auto_process').innerHTML = '��ȡ������Ӧ����Ϣ������ʾ��'+data['message']+" <input type='button' id='ticketing_rest' value='���²�ѯ��Ӧ����Ϣ' title='���²�ѯ��Ӧ����Ϣ' class='btn30' onmouseover=\\"this.className='btn31'\\" onmouseout=\\"this.className='btn30'\\" onclick=\\"get_res_spcorp(resid);\\" />";
					}
				},
				error: function(XMLHttpRequest, textStatus, errorThrown){
					var textStatus_str=textStatus;
					if (textStatus=="timeout") {
						textStatus_str="���糬ʱ,���Ժ�����";
					}else if (textStatus=="error") {
						textStatus_str="��̨����������";
					}
					Fid('auto_process').innerHTML = '��ȡ������Ӧ����Ϣ������ʾ��'+textStatus_str+" <input type='button' id='ticketing_rest' value='���²�ѯ��Ӧ����Ϣ' title='���²�ѯ��Ӧ����Ϣ' class='btn30' onmouseover=\\"this.className='btn31'\\" onmouseout=\\"this.className='btn30'\\" onclick=\\"get_res_spcorp(resid);\\" />";;
						
						
				}
			});
				
		}
		</script>`;
				##------------------------------------------------------------------------------
	}
	print qq!<br><table border=0 cellpadding=0 cellspacing=0 align=center width="600">!;
	
	##�������ɱ��
	if ($in{down_data} eq "Y") {
		
		$workbook->close;		
		if ($@=~/$BUF/) {##�������Excelʧ��         
			$BUF="error";
		}
		my $fileName = $BUF;
		$fileName =~ s/^.*(\\|\/)//; #��������ʽȥ�����õ�·�������õ��ļ���
		$downfile = '/Corp_extra/'.$Corp_ID.'/'.$fileName; 
		if ($BUF eq "error"){
			print qq@
			<tr><td>
			<TABLE align="center" height="100%" width=100% border=0 bgcolor=f0f0f0 cellspacing=0 cellpadding=1 >
				<tr><td height=40 align=center><br><font color=red ><b>����Excel�ļ�ʧ�ܣ���!</b></font></td></tr>			
			</table>
			</td></tr>
			@;
		}else{
			print qq~<form action='/cgishell/golden/admin/report/echo_down.pl' name=dd id='dd' method=post >
					 <input type=hidden name=filename value="$fileName" />
					 <input type=hidden name=User_ID value="$in{User_ID}" />
					 <input type=hidden name=Serial_no value="$in{Serial_no}" />
					 </form>
				<iframe id="rfFrame" name="rfFrame" src="" width="0" height="0" frameborder="0"  style="display:none;"></iframe>
				<script language=javascript >
						Fid('dd').target="rfFrame";
						Fid('dd').submit();
				</script>
				~;  
		}
	}
	print qq!</table>!;
	##------------------------------------------------------------------------------

}
## ������Ʒ�����������Ӧ�̡���ˡ�ҵ������ˡ�������ˣ�����ǰ������  liangby@2016-5-23  
sub inc_account_recv_sp {
	if ($in{Order_type} == 2 && ($in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4)){ ## ������Ʒ��ˡ�ҵ������ˡ�������ˣ�����ǰ������ jf@2018/5/22
	
	}else{
		##ԭ�տʽ����Ϣ  ,��ʾ������ϸʱ�õ���ǰ��������ʽ
		$sql = "select rtrim(Pay_method),Pay_name,Is_netpay,Is_show,Is_payed,Corp_ID,Pay_pic from ctninfo..d_paymethod 
			where  Corp_ID in ('SKYECH','$Corp_center') 
			order by Order_seq,Is_netpay ";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
					$pay_method_hash{$row[0]}[0]=$row[1]; ##����
					$pay_method_hash{$row[0]}[1]=$row[2];
				}
			}
		}
		##��ȡ��ƿ�Ŀ����Ϣ��ϣ��  liangby@2010-12-11
		if ($Pay_version eq "1") {
			%kemu_hash = &get_kemu($Corp_center,"","hash2","","","","assist","N");
		}
	}
	my $must_pay_amount;
	$sql =" select Res_ID,Book_status,In_total,Isnull(Pay_total_sp,0),Inc_title,Inc_id,Old_resid,Tkt_status,Pro_id,Ticket_date,Sp_corp,Is_op,Pro_num,Check_status
		from ctninfo..Inc_book where Res_ID='$in{Reservation_ID}'
		and Sales_ID='$Corp_center' ";
	#print qq!<pre>$sql</pre>!;
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row=$db->ct_fetch)	{
				($old_id,$old_status,$In_total,$old_recv_total,$pro_title,$inc_id,$old_resid,$Is_refund,$old_pro_id,$ticket_time,$old_sp_corp,$old_is_op,$old_pro_num,$old_check_status)=@row;
				if ($Is_refund eq "") {
					$Is_refund="0";
				}
				if ($in{Order_type} == 2 && ($in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4)){
					$message="���";
				}else{
					$message="����";
					$must_pay_amount=$In_total-$old_recv_total;
				}
			}
		}
	}
	if ($old_id eq "") {
	   print MessageBox("������ʾ","����������");
	   exit;
	}
	
	if ($old_status eq "C") {
	   print MessageBox("������ʾ","������ȡ�����޷�����$message����");
	   exit;
	}
	if ($in{Order_type} == 2 && $in{Op} eq 1){
		if($In_total != $old_recv_total){
			print MessageBox("������ʾ","ֻ���Ѹ���Ķ����ſ��Խ�����˲���");
			exit;
		}
	}else{
		$left_total=sprintf("%.2f",$must_pay_amount);
		if ($inc_id ne "") {
			$sql =" select Reward_rate from ctninfo..Inc_goods where Corp_ID='$Corp_center' and Inc_id=$inc_id ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if ($restype==CS_ROW_RESULT)	{
					while(@row=$db->ct_fetch)	{
						$Reward_rate=$row[0];
					}
				}
			}
		}
		if ($in{old_left_total} !=$left_total ) {
		   print MessageBox("������ʾ","��������ѱ仯$in{old_left_total}|$left_total������ʧ��");
		   exit;
		}
	}
	my $sql_upt =" begin transaction sql_insert  \n";
	if ($in{Order_type} == 2 && ($in{Op} eq 1 || $in{Op} eq 3 || $in{Op} eq 4)){
		if($in{Op} eq 1){
			$sql_upt .=" update ctninfo..Inc_book set Settle_checkdate=getdate(),Settle_checkman='$in{User_ID}' where Res_ID='$in{Reservation_ID}' \n";
		}elsif($in{Op} eq 3){
			if (&Binary_switch($Function_ACL{CWFK},0,'A')==0){
				print MessageBox("������ʾ","�Բ�����û��Ȩ�޶Զ���$res_id ����ҵ������˲�����"); 
				exit;
			}
			$sql_upt .=" update ctninfo..Inc_book set Check_status=isnull(Check_status,0)|1  where Res_ID='$in{Reservation_ID}' \n";
		}elsif($in{Op} eq 4){
			if( &Binary_switch($Function_ACL{CWFK},1,'A')==0 ){
				print MessageBox("������ʾ","�Բ�����û��Ȩ�޶Զ���$res_id ���в�����˲�����"); 
				exit;
			}
			if($logo_path =~ /f/ && ($old_check_status & 1) != 1){ ## ���������ҵ������˱����Ⱦ���ҵ�������
				print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ����ҵ������˲�����"); 
				exit;
			}
			$sql_upt .=" update ctninfo..Inc_book set Check_status=isnull(Check_status,0)|2  where Res_ID='$in{Reservation_ID}' \n";
		}
	}else{
		if($logo_path =~ /f/ && $logo_path !~ /g/ && ($old_check_status & 1) != 1){ ## ֻ����ҵ�������
				print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ����ҵ������˲�����"); 
				exit;
		}
		if($logo_path !~ /f/ && $logo_path =~ /g/ && ($old_check_status & 2) != 2){ ## ֻ���ò������
			print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ���в�����˲�����"); 
			exit;
		}
		if($logo_path =~ /f/ && $logo_path =~ /g/ ){ ## ����ҵ������ˡ��������
			if(($old_check_status & 1) != 1){
				print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ����ҵ������˲�����"); 
				exit;
			}
			if(($old_check_status & 2) != 2){
				print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ���в�����˲�����"); 
				exit;
			}
		}

		my $pay_type_t=$p_Pay_type;
		$sql_upt .=" delete from ctninfo..Inc_book_sppay
					 where Res_ID='$in{Reservation_ID}' 
						and Op_type in ('G','S') and Op_date=convert(char(10),getdate(),102)  and Sales_ID='$Corp_center' 
					update ctninfo..Inc_book_sppay set Left_total=0
						 where Res_ID='$in{Reservation_ID}'  and Op_type+'' in ('','H','G','S') and Op_date=convert(char(10),getdate(),102)  and Sales_ID='$Corp_center'  \n";
											
		$sql_upt .=" update ctninfo..Inc_book set Pay_total_sp=Isnull(Pay_total_sp,0)+$in{recv_total} where Res_ID='$in{Reservation_ID}' \n";

		my $sub_comment;
		if ($p_pingzheng ne "") {
			if ($in{Remark} ne "") {
				$sub_comment .=",";
			}
			$sub_comment .="ƾ֤��$p_pingzheng";
		}

		my $left=$must_pay_amount+(-1*$in{recv_total});
		$sql_upt .=" insert into ctninfo..Inc_book_sppay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,Pay_bank,CID_corp,Op_type)
			select '$in{Reservation_ID}',isnull(max(Pay_serial)+1,0),'$p_Pay_type',$must_pay_amount,$in{recv_total},0,'$in{User_ID}',getdate(),convert(char(10),getdate(),102),
				'$in{Remark}$sub_comment$payment_str','$p_pingzheng','$Corp_center','$Corp_ID','$p_Pay_type2','$sp_corp','H'
			 from ctninfo..Inc_book_sppay where Res_ID='$in{Reservation_ID}'  \n";
		if ($old_pro_id eq "29") {##�հ׵����湩Ӧ���Ѹ������
			$sql_upt  .=" update ctninfo..Inc_book_detail set  Ds_recv=Isnull(Ds_recv,0)+$in{recv_total} where Res_ID='$in{Reservation_ID}' and Birthday='$sp_corp' \n";
		}
		my $pay_type3=$p_Pay_type;
		if ($left !=0) {
			$sql_upt .=" insert into ctninfo..Inc_book_sppay(Res_ID,Pay_serial,Pay_method,Price_total,Recv_total,Left_total,User_ID,Op_time,Op_date,Remark,Trade_no,Sales_ID,Corp_ID,Pay_bank,CID_corp,Op_type)
			select '$in{Reservation_ID}',isnull(max(Pay_serial)+1,0),'$pay_type3',$left,0,$left,'$in{User_ID}',getdate(),convert(char(10),getdate(),102),
				'$in{Remark}','','$Corp_center','$Corp_ID','','$sp_corp','G'
			 from ctninfo..Inc_book_sppay where Res_ID='$in{Reservation_ID}'  \n";
		}
		if ($old_pro_id eq "27") {#�������
			## ��ѯ�Ƿ�Ϊ�ⲿBSP���������޸�Ʊ֤���ͣ���ȻƱ̨�˶Ի������
			my $office_type;
			my $sql1 = "select a.Out_tkt from ctninfo..Corp_office a where a.Office_ID='$in{sp_corp}'";
			$db->ct_execute($sql1);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$office_type=$row[0];
					}
				}
			}
			$op_name="��������";
			if ($old_is_op ne "H") {	## δ����
				$sql_upt .="update ctninfo..Inc_goods set Sales_num=Sales_num+$old_pro_num where Corp_ID='$Corp_center' and Inc_id=$inc_id \n";
				$sql_upt .="update ctninfo..Inc_book set Is_op='Y' where Sales_ID='$Corp_center' and Res_ID='$in{Reservation_ID}' \n";
			}
			my ($pay_bank,$pay_kemu)=($p_Pay_type2,$p_Pay_type);
			my $new_status="H";
			$sql_upt .="update ctninfo..Inc_book set Book_status='$new_status',User_rmk='$in{Remark}',
				Pay_method='$pay_kemu',Batch_no='$pay_bank',Pay_user='$in{User_ID}',Pay_date=convert(char(10),getdate(),102)
				where Sales_ID='$Corp_center' and Res_ID='$in{Reservation_ID}' and Order_type=null \n";
			## �޸Ļ�Ʊ������Ʊ֤���͡�Ʊ֤��Դ�������Ŀ�����ʽ	 dabin@2016-03-29
			$sql_upt .="update ctninfo..Airbook_$Top_corp set a.Pay_bank='$pay_bank',a.Pay_kemu='$pay_kemu',a.Office_ID='$in{sp_corp}',a.Settle_date=getdate()
					from ctninfo..Airbook_$Top_corp a,
						ctninfo..Inc_book_detail b
					where a.Reservation_ID=b.Cust_name
						and b.Res_ID='$in{Reservation_ID}' \n";
			$sql_upt .="update ctninfo..Inc_book set a.Batch_no='$pay_bank',a.Pay_method='$pay_kemu',a.Sp_corp='$in{sp_corp}'
					from ctninfo..Inc_book a,
						ctninfo..Inc_book_detail b
					where a.Res_ID=b.Cust_name
						and b.Res_ID='$in{Reservation_ID}' \n";
			if ($office_type =~ /[YP]/) {	## �⹺/ƽ̨
				$sql_upt .="update ctninfo..Airbook_detail_$Top_corp set a.Is_ET='W' 
					from ctninfo..Airbook_detail_$Top_corp a,
						ctninfo..Inc_book_detail b
					where a.Reservation_ID=b.Cust_name
						and b.Res_ID='$in{Reservation_ID}' \n";
			}
		}
		$t_recv_total=$in{recv_total};
		if ($in{recv_total} !=$left_total) {##Ƿ��
		
			$sql_upt .=" insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) 
				values('$in{Reservation_ID}','G','$in{User_ID}','3',getdate()) ";
		}else{
		
			$sql_upt .=" insert into ctninfo..Res_op(Reservation_ID,Res_type,Operator,Operate_type,Operate_time) 
				values('$in{Reservation_ID}','G','$in{User_ID}','4',getdate()) ";
			
		}
		#����
		$sql_upt .=" delete ophis..Op_rmk where Sales_ID='$Corp_center' and Product_type='I' and Res_ID='$in{Reservation_ID}' and Op_type='2' \n";
		if ($in{pay_attach} ne "") {
			$sql_upt .=" insert into ophis..Op_rmk values('$in{Reservation_ID}','$Corp_center','$in{User_ID}',getdate(),'2','I','$in{pay_attach}','$Corp_ID') \n";
		}
	}
	#return $sql_upt;
	#print "<Pre>$sql_upt";
	#exit;
	my $Update = 0;
	$db->ct_execute($sql_upt);
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
		$db->ct_execute("Commit Transaction sql_insert");
		#$db->ct_execute("Rollback Transaction sql_insert");
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
				}
			}
		}
		return "<font color='blue'>$in{Reservation_ID}���������ɹ���</font></br>";
	}
	else{
		$db->ct_execute("Rollback Transaction sql_insert");
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
				}
			}
		}
		return "<font color='red'>$in{Reservation_ID}��������ʧ�ܣ�</font></br>";
	}
	
}
### --------------------------------
### ��Ʊ��Ӧ�̸���           liangby@2016-7-25
### ---------------------------------
sub air_account_sp{
	local($type,$op)=@_;
	#office_name
	$sql=" select rtrim(Office_ID),Office_name from ctninfo..Corp_office where Corp_ID='$Corp_center' ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				$office_name{$row[0]}=$row[1];
			}
		}
	}

	## ��Ӧ�������˺� jf@2018/3/19
	$sql="select d_pid,d_group_name from ctninfo..d_dict where d_corp='$Corp_center' and d_group_id=46 order by d_dis_order ";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if($restype==CS_ROW_RESULT){
			while(@row = $db->ct_fetch){
				$bank_account_info{$row[0]}=$row[1];
			}
		}
	}
	$Start = $in{Start};	
	## ---------------------------------------------------------------------
	## define table header
	##��ȡ�û���Ϣ
	&get_userinfos("","O','S','Y","Y");
	## Ʊ֤����
	my %tkt_type=&get_dict($Corp_center,3,"","hash");
	my %kemu_hash = &get_kemu($Corp_center,"","hash2","","","","assist","N");
	my @kemu_array=&get_kemu($Corp_center,"","array","3","Y","","assist","N","","");
	for (my $i = 0; $i < scalar(@kemu_array); $i++) {
		
		push(@tmp_kemu_array, "['$kemu_array[$i]{Corp_ID}', '$kemu_array[$i]{Type_ID}', '$kemu_array[$i]{Type_name}','$kemu_array[$i]{Pic}','$kemu_array[$i]{Pid}']");
		$assist_hash{$kemu_array[$i]{Type_ID}}=$kemu_array[$i]{Type_name};
	}
	$kemulist = join(',', @tmp_kemu_array);

	$getscript=qq! onchange="get_paykemu();"!;
	
	if ($in{down_data} eq "Y") {
		$dw_hidden = "none";
	}else{
		$dw_hidden = "block";
	}

	$Header = qq!<form action='air_account_fk.pl' method=post name=book id='book_form' style="display:$dw_hidden">
	<span id='printTitle'></span>
	<span id='printSpan'>
	<table width="98%" border="0" cellspacing="1" cellpadding="1" bgcolor="dadada" >
		<tr align="center" bgcolor="#efefef">!;
	if ($query_only ne "Y" && ($op == 2 ||$op == 0 || $op == 3 || $op == 4)){	
		$Header .= qq!<td width="30" height="30">����</td>!;
	}else{
		$Header .= qq!<td width="30" height="30">&nbsp;</td>!;
	}
	my $tb_book="_$Top_corp";
	if ($in{History} eq "Y") {	$tb_book="$in{his_year}";	}
	$Header .= qq!
	<td>������</td>
	<td>��Ӧ��</td>
	<td>PNR</td>
	<td>��Ʊ����</td>
	<td>Ʊ֤</td>
	<td>��Ʊ����</td>
	<td>��������</td>
	<td>�������</td>
	<td>�����</td>
	<td>��������</td>
	<td>��������</td>
	<td>�����</td>
	<td>�����</td>
	<td>����</td>
	<td nowrap>Ʊ��</td>
	<td width=40>SCNY</td>
	<td width=30>����˰</td>
	<td width=30>�����</td>
	<td width=30>����������</td>
	<td>Ӧ�ջ�Ʊ��</td>
	<td>������</td>\n!;

	$Header.=qq!</tr>!;
	print "$Header";
	## define table tailer

	## ---------------------------------------------
	## ���ڼ��
	## ---------------------------------------------
	if(&date_check($Depart_date)==0){
		print qq!<h3 class="tishi">������ʾ�����鿪ʼ���������Ƿ���ȷ��</h3>!;
		exit;
	}
	## ---------------------------------------------------------------------
	&show_air_js();
	print qq?\n<script>	
	// ��ȡDOMԪ�أ���ֹ&air_account_sp�����ҳ����ö�δ�ҵ�Fid���� jf on 2018/5/23
	function Fid(id){  
		return typeof(id) === "string"\?document.getElementById(id):id;    
	}
	function OpenWindow(theURL,winName,features) { 
	  window.open(theURL,winName,features);
	}
	function Show_relate(resid,pnr){
		OpenWindow('air_relate.pl\?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&PNR='+pnr+'&Reservation_ID='+resid,'R_'+resid,'scrollbars,width=360,height=280');
	}
	function Show_ban(resid,type){
		if (type == 'win') {
			pmwin('open', '/cgishell/golden/admin/airline/res/air_ban_do.pl\?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&Refresh=win', '��ƺ���',680,500);
		}
		else{
			OpenWindow('/cgishell/golden/admin/airline/res/air_ban_do.pl\?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Reservation_ID='+resid+'&Refresh=N','H_'+resid,'resizable,scrollbars,width=680,height=400,left=200,top=200');
		}
	}
	</script>?;
	## ----------------------------------------------------------------------------
	print qq!<div class="airlines_list scroll_chaoc">!;
	## =================================================================================
	$where = "\n from ctninfo..Airbook$tb_book a,
		ctninfo..Airbook_lines$tb_book c,
		ctninfo..Airbook_detail$tb_book g
	WHERE a.Reservation_ID = c.Reservation_ID 
		and a.Reservation_ID=g.Reservation_ID 
		and c.Reservation_ID=g.Reservation_ID 
		and c.Res_serial=g.Res_serial
		 \n";


	$where .= "and a.Sales_ID = '$Corp_center' \n";
	##���ﲻӦ��ƥ����ȡ���Ķ���    liangby@2014-2-11
	$where .= " and a.Book_status in ('Y','P','S','H') ";
	$where_the=$where;
	if ($Corp_type ne "T") {
		if ($in{History} eq "Y" || $in{pay_obj} eq "P" ){##��ʷ�����ó�Ʊ��������     liangby@2008-12-30
			if (($Corp_center eq "KWE116" || $Corp_center eq "CTU300") &&  $Is_delivery eq "Y" && ($in{Corp_ID} ne "" ||
				 $in{Res_ID} ne "" || length($in{PNR}) == 5 || length($in{PNR}) == 6 || length($in{tkt_id}) >= 10 ) ) {	
				## ����������Ӫҵ��ָ���ͻ���ѯ��Ӧ�ܲ�ѯ���ͻ����ж���	dabin@2011-11-18
				##�ö����ţ������Ʊ�Ų�Ҳ������   liangby@2011-12-15
			}else{
				$where .= "and a.Agent_ID='$Corp_ID'  \n";
			}
		}else{	## ���ͻ���
			if (($Corp_center eq "KWE116" || $Corp_center eq "CTU300") && $Is_delivery eq "Y" && ($in{Corp_ID} ne "" ||
				 $in{Res_ID} ne "" || length($in{PNR}) == 5 || length($in{PNR}) == 6 || length($in{tkt_id}) >= 10 ) ) {	
				## ����������Ӫҵ��ָ���ͻ���ѯ��Ӧ�ܲ�ѯ���ͻ����ж���	dabin@2011-11-18
				##�ö����ţ������Ʊ�Ų�Ҳ������   liangby@2011-12-15
			}
			else{
				$where .= "and a.Send_corp ='$Corp_ID'  \n";	
			}
		}				
	}
	if ($in{Res_ID} ne "") {##������
		if (index($in{Res_ID},",")>-1) {##�����Ŵ�
			my @res_temp=split(",",$in{Res_ID});
			my $res_str = join ("','",@res_temp);
			$where .=" and a.Reservation_ID in ('$res_str') and a.Book_status <> 'C' \n";
		}
		else{
			$where .=" and a.Reservation_ID='$in{Res_ID}' and a.Book_status <> 'C' \n";
		}
	}
	elsif ($in{re_other} ne "Y" && $in{tkt_id} ne "") {##ƥ���λƱ��,������������   liangby@2012-2-8
		my @tkt_id=split(',',$in{tkt_id});my $tkt_len=length($in{tkt_id});
		if (scalar(@tkt_id)==1 && $tkt_len<10) {
			$where .=" and right(rtrim(convert(varchar,g.Ticket_ID)),$tkt_len)='$in{tkt_id}' ";
		}elsif(scalar(@tkt_id)>=1){
			for (my $i=0;$i<scalar(@tkt_id) ;$i++) {
				$tkt_id[$i]=sprintf("%.0f",$tkt_id[$i]);
			}
			my $tkt_id=join(',',@tkt_id);
			$where .=" and g.Ticket_ID in($tkt_id) \n";
		}
		if ($op != 8) {#fanzy@2012-6-12
			$where .=" and a.Ticket_time >= dateadd(month,-1,'$Depart_date')\n";
		}
	}else{
		if ($in{air_type} ne "" && $in{air_type} ne "ALL") {##���ӹ��ں͹�������              liangby@2008-7-22
			$where .=" and a.Air_type ='$in{air_type}' ";
		}
		if (length($in{PNR}) == 5 || length($in{PNR}) == 6) {
			$in{PNR} =~ tr/a-z/A-Z/;
			$where .= " and a.Booking_ref = '$in{PNR}' \n"; 
		}elsif ($in{re_other} ne "Y" && $in{tkt_id} ne "") {##ƥ���λƱ��,������������   liangby@2012-2-8
			my @tkt_id=split(',',$in{tkt_id});my $tkt_len=length($in{tkt_id});
			if (scalar(@tkt_id)==1 && $tkt_len<10) {
				$where .=" and right(rtrim(convert(varchar,g.Ticket_ID)),$tkt_len)='$in{tkt_id}' ";
			}elsif(scalar(@tkt_id)>=1){
				for (my $i=0;$i<scalar(@tkt_id) ;$i++) {
					$tkt_id[$i]=sprintf("%.0f",$tkt_id[$i]);
				}
				my $tkt_id=join(',',@tkt_id);
				$where .=" and g.Ticket_ID in($tkt_id) \n";
			}
			if ($op != 8) {#fanzy@2012-6-12
				$where .=" and a.Ticket_time >= dateadd(month,-1,'$Depart_date')\n";
			}
		}
		else{
			if ($in{date_type} eq "B") {##��������
				$where .= "and a.Settle_date >= '$Depart_date'
					and a.Settle_date < '$End_date'\n";
			}
			elsif ($in{date_type} eq "A") {
				$where .= "and c.Air_date >= '$Depart_date'
					and c.Air_date < '$End_date'\n";
			}elsif ($in{date_type} eq "C") {##�����������
				$where .= "and a.Settle_checkdate  >= '$Depart_date' and a.Settle_checkdate < '$End_date' \n";
			}
			else{
				$where .= "and a.Ticket_time >= '$Depart_date'
					and a.Ticket_time < '$End_date'\n";
			}

			if ($in{re_other} eq "Y" && $in{tkt_id} ne "") {##ƥ���λƱ��,������������   liangby@2012-2-8
				my @tkt_id=split(',',$in{tkt_id});my $tkt_len=length($in{tkt_id});
				if (scalar(@tkt_id)==1 && $tkt_len<10) {
					$where .=" and right(rtrim(convert(varchar,g.Ticket_ID)),$tkt_len)='$in{tkt_id}' ";
				}elsif(scalar(@tkt_id)>=1){
					for (my $i=0;$i<scalar(@tkt_id) ;$i++) {
						$tkt_id[$i]=sprintf("%.0f",$tkt_id[$i]);
					}
					my $tkt_id=join(',',@tkt_id);
					$where .=" and g.Ticket_ID in($tkt_id) \n";
				}
				if ($op != 8) {#fanzy@2012-6-12
					$where .=" and a.Ticket_time >= dateadd(month,-1,'$Depart_date')\n";
				}
			}
	


			if ($in{team_name} ne "") {	$in{team_name}=~ tr/a-z/A-Z/; $where .=" and a.Team_name='$in{team_name}'\n";	}
			##Ʊ֤״̬
			my @tk_status;
			($in{tk_status_0} ne "")?push(@tk_status,"$in{tk_status_0}"):1;
			($in{tk_status_1} ne "")?push(@tk_status,"$in{tk_status_1}"):1;
			($in{tk_status_2} ne "")?push(@tk_status,"$in{tk_status_2}"):1;
			($in{tk_status_3} ne "")?push(@tk_status,"$in{tk_status_3}"):1;
			($in{tk_status_4} ne "")?push(@tk_status,"$in{tk_status_4}"):1;
			($in{tk_status_5} ne "")?push(@tk_status,"$in{tk_status_5}"):1;
			if (scalar(@tk_status)>0 ) {
			   $tk_status=join("','",@tk_status);
			   $where .=" and a.Alert_status in ('$tk_status') ";
			}
	
			if ($op == 0) {	##δ����	
				if($logo_path =~ /f/ && $logo_path !~ /g/){## ֻ����ҵ�������
					$where .= "	and (a.Pay_bank+'' in ('N','') or a.Settle_date=null ) and a.Check_status&1=1 and a.Check_status&3<>3 \n ";	
				}elsif($logo_path !~ /f/ && $logo_path =~ /g/){## ֻ���ò������
					$where .= "	and (a.Pay_bank+'' in ('N','') or a.Settle_date=null ) and a.Check_status&2=2 and a.Check_status&3<>3 \n ";	
				}elsif($logo_path =~ /f/ && $logo_path =~ /g/){## ������
					$where .= "	and (a.Pay_bank+'' in ('N','') or a.Settle_date=null ) and a.Check_status&3=3 \n ";	
				}else{ ## ��������
					$where .= "	and (a.Pay_bank+'' in ('N','') or a.Settle_date=null ) \n ";	
				}
			}elsif ($op == 1) {	## �Ѹ�������
				$where .= "and a.Pay_bank+'' not in ('N','') and a.Settle_date !=null and a.Settle_checkdate=null  \n";	
			}elsif ($op == 2) {	## ������ Ƿ��	
				$where .= "and a.Pay_bank+'' not in ('N','') and a.Settle_date !=null and a.Settle_checkdate !=null  \n";	
			}elsif ($op == 3) {	## ҵ�������	
				$where .= "and (a.Pay_bank+'' in ('N','') or a.Settle_date=null ) and a.Check_status=null \n";	
			}elsif ($op == 4) {	## �������	
				if($logo_path =~ /f/ ){ ## ���������ҵ�������	
					$where .= "and (a.Pay_bank+'' in ('N','') or a.Settle_date=null ) and a.Check_status&1=1 and a.Check_status&3<>3 \n";	
				}else{
					$where .= "and (a.Pay_bank+'' in ('N','') or a.Settle_date=null ) and a.Check_status=null \n";	
				}
			}else{
				print "<div align=left><br><font color=red>��ʾ���Բ�����ʱ��֧�ָò�����</div></td></tr></table>";
				exit;
			}
			
			if($in{et_type} ne "ALL"){
				$where .=" and g.Is_ET ='$in{et_type}' ";
			}

			if ($in{office_id} ne "") {
				$where .=" and a.Office_ID='$in{office_id}' ";
			}
			if ($in{user_book} ne "") {	$where .=" and a.Book_ID='$in{user_book}'\n";}
		
			if ($in{PY_name} ne "") {	 ##�������ƴ������(ģ����ѯ)		linjw@2016-05-31
				$in{PY_name} =~ tr/a-z/A-Z/;				
				$where .= " and g.PY_name like '%$in{PY_name}%' \n";
			}			
			if ($in{pay_by1} ne ""){
				$where .= "and a.Pay_bank = '$in{pay_by1}'  \n";
			}
			if ($in{Agent_ID_group} ne "") {
				@Age_ID_arr = split /,/,$in{Agent_ID_group};
				@Age_per = ();
				$Age_str = "";
				$tag = "Y";
				foreach $tt (@Age_ID_arr) {
					if ($tt eq 'ALL') {
						$tag = "N";
						last;
					}else{
						push(@Age_per,"'".$tt."'");
					}
				}
				if ($tag ne "N") {
					$Age_str = join ',',@Age_per;
					$where .= " and a.Agent_ID in ($Age_str) \n";
				}
			}
		}
		
	}


	if ($in{down_data} eq "Y") {
		## �½�Excel����
		my $root_path="d:/upload/";
		if (! -e $root_path) {#Ŀ¼������
			 mkdir($root_path,0002);
		}elsif(!-d $root_path){#�����ļ�������Ŀ¼
			 mkdir($root_path,0002);
		}
		my $r_path="d:/upload/report_file/";
		if (! -e $r_path) {#Ŀ¼������
			 mkdir($r_path,0002);
		}elsif(!-d $r_path){#�����ļ�������Ŀ¼
			 mkdir($r_path,0002);
		}
		my $path="d:/upload/report_file/$Corp_ID/";
		if (! -e $path) {#Ŀ¼������
			 mkdir($path,0002);
		}elsif(!-d $path){#�����ļ�������Ŀ¼
			 mkdir($path,0002);
		}
		my $ttime=$time;
		$ttime=~ s/\:*//g;
		my $ttoday=$today;
		$ttoday=~ s/\.*//g;
		my $context = new MD5;
		$context->reset();
		$context->add($year.$ttoday.$ttime.$Corp_ID."mfssdfdsfdfdsfde4423");
		my $md5_filename = $context->hexdigest;
		$BUF= $path.$md5_filename.".xls";
		$del_link="d:/www/Corp_extra/$Corp_ID/";
		$workbook;
		$workbook= Spreadsheet::WriteExcel::Big->new($BUF); 

		# �¼�һ�������� 
		$worksheet = $workbook->addworksheet("��Ƚ����");
		##���ݸ�ʽ
		$format1 = $workbook->addformat();
		## 9������
		$format1->set_size(9);
		$format1->set_color('black');
		$iRow=0;
		$iCol=0;
		$worksheet->write_string($iRow,$iCol,"������",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��Ӧ��",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"PNR",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��Ʊ����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"Ʊ֤",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��Ʊ����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��������",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"�������",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��������",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"��������",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"�ͻ�����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"Ʊ��",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"SCNY",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"����˰",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"����������",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"Ӧ�ջ�Ʊ��",$format1);$iCol++;
		$worksheet->write_string($iRow,$iCol,"������",$format1);$iCol++;
		$iRow=1;
		$iCol=0;
	}
	$User_intax="Y";	
	if ($G_ZONE_ID ne "3" && $center_airparm !~/s/ && ($center_airparm !~/q/ || $center_airparm !~/o/ ) ) {
		$User_intax="N";   ##�ɰ�鿴����ҳ�治ʹ�ý���˰   liangby@2018-1-15
	}
	my $i=$w = 0;
	$sql="select rtrim(a.Reservation_ID),right(convert(char(10),c.Air_date,102),5),c.Departure,c.Arrival,
		a.Office_ID,g.Res_serial,rtrim(c.Airline_ID+c.Flight_no),g.First_name,
		g.Seat_type,g.Is_ET,g.In_price,g.SCNY_price,a.Book_status,convert(char(10),a.Ticket_time,102),
		convert(char(10),a.Settle_date,102),convert(char(10),a.Settle_checkdate,102),rtrim(a.Settle_checkman),
		a.Pay_kemu,a.Pay_bank,rtrim(a.Booking_ref),g.Air_code,g.Ticket_ID,(case when (datediff(day,'2017.12.01',a.Book_time) >=0 and '$User_intax'='Y' ) then isnull(g.In_tax,g.Tax_fee)+isnull(g.In_yq,g.YQ_fee) else g.Tax_fee+g.YQ_fee end),
		a.In_total,a.ET_price,a.Corp_ID,g.Ticket_LID,rtrim(a.Settle_ID),a.Agt_total,a.Other_fee,a.Service_fee,a.Insure_out,a.Agent_ID
		"; 
	my @temp_book=();#	fanzy@2012-11-1

	$sql .= $where;
	$sql .= " order by a.Office_ID,a.Book_time,a.Reservation_ID,g.Res_serial,g.Ticket_ID "; 
	#print "<pre>$sql";
	## ---------------------------------------------------------------------
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				push(@temp_book,[@row]);
				push(@resid,$row[0]);
				$memberid{$row[0]}=$row[4];	## ��Ա����
				if($row[49] eq "1" && $row[61]=~/\d{10,}/){  ##ԭ������
					push(@oldresid,$row[61]);
				}
			}
		}
	}
	## �����ظ��Ķ����ţ����������з�ҳ����	dabin@2012-12-27
	
	%count=();

	@resid=grep { ++$count{ $_ } < 2; } @resid;
	$Total_num=scalar(@resid);
	my $records = $in{perpage} eq '' ? 20 : $in{perpage};
	$Start = $in{Start};	if($in{Start} eq "" || $in{Start} eq " ") { $Start=1; }
	if ($records == $Total_num) {	$Start=1;	}
	if ($in{nopaging} eq "Y"){ $records = $Total_num; $Start=1;}
    %ccptd=();my @HCityRs=();
	my $temp_id = $tid = $corpid = $tmp_serial = "";
	my $Air_date = "";
	$ii = -1;
	my $Find_res = 0;
	my $order_serial=0;
	my %pay_amount=();
	@price=(0,0,0,0);
	my $Total_count=0;
	##��ȡ�û���Ϣ
	&get_userinfos("","O','S','Y","");
	for (my $k=0;$k<scalar(@temp_book) ;$k++) {
		my @row=@{$temp_book[$k]};
		if ($tid ne $row[0]){	## �¶���
			$tid = $row[0];		$Find_res ++;
			$order_serial=0;
		}
		if ($in{down_data} eq "Y") {
			my $s_city=$row[2]; my  $e_city=$row[3];
			my $sp_corp=$row[4];  
			my $is_et=$row[9];  my $in_price=$row[10];  my $scny_price=$row[11];
			my $ticket_tmp=$row[13];  my $Settle_date=$row[14];  my $Settle_checkdate=$row[15]; $Settle_checkman=$row[16];
			my $Pay_kemu=$row[17];
			$Pay_kemu=~ s/\s*//g;
			my $bank_id=$row[18];  $a_code_dw=$row[20];     my $tk_id=$row[21];  my $tax=$row[22];
			my $lid=$row[26];		  my $airfare=sprintf("%.2f",$row[28]+$row[29]+$row[30]+$row[31]);
			my $et_price=$row[24];	  my $payer=$row[27];
			if ($et_price eq "" || $et_price ==0 || $is_et eq "Y") {##BSP��Щ ET_priceû��In_totalͬ����   liangby@2016-12-8
				$et_price=$row[23];
			}
			my $bank_name;		   
			if ($Settle_date eq "") {
				$Settle_date="-";
			}
			if ($Settle_checkdate eq "") {
				$Settle_checkdate="-";
			}
			if ($Settle_checkman eq "") {
				$Settle_checkman="-";
			}
			if ($payer eq "") {
				$payer="-";
			}
			
			my $first_row="N";
			if ($temp_id_dw ne $row[0]) {
				$first_row="Y";
			}
			#if ($temp_id_dw ne $row[0]){	## �¶���
				#$first_row="Y";
				
				if ($bank_id eq "N") {
					$bank_name="δ����";
				}elsif($kemu_hash{$bank_id}[0] ne ""){
					$bank_name=$kemu_hash{$bank_id}[0];
				}else{
					$bank_name="---";
				}
				$tmp_serial_dw = $row[5];
				my $pnr=$row[19];
				if ($pnr eq "") {	$pnr="--";	}
				$Air_date=$row[1];	
				my $et_name="---";
				if ($tkt_type{$is_et} ne "") {
					$et_name=$tkt_type{$is_et};
				}
				my $sp_corp_name=$sp_corp;
				if ($office_name{$sp_corp} ne "") {
					$sp_corp_name=$office_name{$sp_corp};
				}
				my $tkt_tmp=substr($ticket_tmp,2,8);
				$temp_id_dw = $row[0];$Res_serial_dw=0;
				$worksheet->write_string($iRow,$iCol,$row[0],$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$sp_corp_name,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$pnr,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$tkt_tmp,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$et_name,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,"$row[32] $Corp_csname{$row[32]}",$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$Settle_date,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$Settle_checkdate,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$Settle_checkman,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$bank_name,$format1);$iCol++;
				$worksheet->write_number($iRow,$iCol,$Air_date,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$s_city.$e_city,$format1);$iCol++;
				$worksheet->write_string($iRow,$iCol,$row[6],$format1);$iCol++;
				
			#}
			#else{
			#	if( $tmp_serial_dw eq $row[5]){	## �Ϻ���
			#		if ($op == 1 ||$op == 0){
			#			$iCol=12;
			#		}else{
			#			$iCol=11;
			#		}
			#	}
			#	else{	## �º���
			#		if ($op == 1 ||$op == 0 ){
			#			$iCol=9;
			#		}else{
			#			$iCol=8;
			#		}
			#		$tmp_serial_dw = $row[5];$Res_serial_dw++;
			#		$Air_date=$row[1];
			#		$worksheet->write_number($iRow,$iCol,$Air_date,$format1);$iCol++;
			#		$worksheet->write_string($iRow,$iCol,$s_city.$e_city,$format1);$iCol++;
			#		$worksheet->write_string($iRow,$iCol,$row[6],$format1);$iCol++;
			#	}
			#			}
			my $tktno=$a_code_dw."-".$tk_id;
			if ($lid>0) {
				$tktno .="0".$lid;
			}
			$worksheet->write_string($iRow,$iCol,$CORP_NAME{$row[25]}[3],$format1);$iCol++;
			$worksheet->write_string($iRow,$iCol,$row[7],$format1);$iCol++;
			$worksheet->write_string($iRow,$iCol,$tktno,$format1);$iCol++;
			$worksheet->write_number($iRow,$iCol,$scny_price,$format1);$iCol++;
			$worksheet->write_number($iRow,$iCol,$tax,$format1);$iCol++;
			$worksheet->write_number($iRow,$iCol,$in_price,$format1);$iCol++;
			if ($first_row eq "Y") {
				$worksheet->write_number($iRow,$iCol,$et_price,$format1);$iCol++;
				$worksheet->write_number($iRow,$iCol,$airfare,$format1);$iCol++;
			}else{
				$worksheet->write_number($iRow,$iCol,0,$format1);$iCol++;
				$worksheet->write_number($iRow,$iCol,0,$format1);$iCol++;
			}
			$worksheet->write_string($iRow,$iCol,$payer,$format1);$iCol++;

			$iCol=0;
			$iRow++;
		}

		if($Find_res<=$Start*$records && $Find_res>($Start-1)*$records ){
			my $s_city=$row[2]; my  $e_city=$row[3];
			my $sp_corp=$row[4];  
			my $is_et=$row[9];  my $in_price=$row[10];  my $scny_price=$row[11];
			my $ticket_tmp=$row[13];  my $Settle_date=$row[14];  my $Settle_checkdate=$row[15]; $Settle_checkman=$row[16];
			my $Pay_kemu=$row[17];
			$Pay_kemu=~ s/\s*//g;
			my $bank_id=$row[18];	my $a_code=$row[20];     my $tk_id=$row[21];  my $tax=$row[22];
			my $lid=$row[26];		my $payer=$row[27];
			my $et_price=$row[24];  my $airfare=sprintf("%.2f",$row[28]+$row[29]+$row[30]+$row[31]);
			if ($et_price eq "" || $et_price ==0 || $is_et eq "Y") {##BSP��Щ ET_priceû��In_totalͬ����   liangby@2016-12-8
				$et_price=$row[23];
			}
			my $bank_name;		   
			if ($Settle_date eq "") {
				$Settle_date="-";
			}
			if ($Settle_checkdate eq "") {
				$Settle_checkdate="-";
			}
			if ($Settle_checkman eq "") {
				$Settle_checkman="-";
			}
			if ($payer eq "") {
				$payer="-";
			}
			my $first_row="N";
			if ($temp_id ne $row[0]){	## �¶���
				$first_row="Y";
				
				if ($bank_id eq "N") {
					$bank_name="δ����";
				}elsif($kemu_hash{$bank_id}[0] ne ""){
					$bank_name=$kemu_hash{$bank_id}[0];
				}else{
					$bank_name="&nbsp;";
				}
				$tmp_serial = $row[5];
				my $pnr=$row[19];
				if ($pnr eq "") {	$pnr="--";	}
				else{
					$pnr = qq!<a href="javascript:Show_pnr('$row[0]','$pnr');" title='��ȡ����'>$pnr</a>!;						
				}
				print qq!<tr class="odd" onmouseout="this.style.background='#ffffff'" onmouseover="this.style.background='#fef6d5'" align=center >!;
			
				$Air_date=$row[1];	
				if ($temp_id ne "") {
					$out_total = $total_tmp;
					$total_tmp = 0;
					$comm_t = $comm_tmp;
					$comm_tmp = 0;
					push(@o_price,$out_total);	push(@i_price,$out_total);	push(@c_comm,$comm_t);	

				}
				
				push(@i_select,0);
				push(@lock,$is_lock); 
				if (($op == 0 || $op == 1 || $op == 3 || $op == 4) && $in{History} ne "Y"){##����ͨ���ͻ���ѯʱ����������������     
					my $l_dis;
			
					if ($is_lock ne "1" && $l_dis eq "") { ## ѡ��ȫ��js
					   #$ck_all .= "document.book.cb_$i.checked = document.book.cb.checked;\n";
					}
					my $clickEvent="sum_amount();";
					if ($op == 3 || $op == 4){
						$clickEvent="void(0);";
					}
					print qq!<td align=center width=30>
						<input type=checkbox  name="cb_$i" id="cb_$i" value='$row[0]' onclick="$clickEvent" class="radio_publish">
						</td>!;
				}
				else{	print "<td>&nbsp;</td>";	}
				my $et_name="&nbsp;";
		
				if ($tkt_type{$is_et} ne "") {
					$et_name=$tkt_type{$is_et};
				}
				my $sp_corp_name=$sp_corp;
				if ($office_name{$sp_corp} ne "") {
					$sp_corp_name=$office_name{$sp_corp};
				}
				my $tkt_tmp=substr($ticket_tmp,2,8);
				print qq!\n
				<td align=center><a href="javascript:Show_book('$row[0]');" title='�鿴����'>$row[0]</a></td>
				<td><a href="javascript:Show_ban('$row[0]');" title="��ƺ���\n�����˺ţ�$bank_account_info{$sp_corp}">$sp_corp_name</a></td>
				<td align=center>$pnr</a></td>
				<td title='$ticket_tmp'>$tkt_tmp</td>
				<td align=center><a href="javascript:Show_his('$row[0]');" title='������¼' name="et_type_$i" id="et_type_$i" value=$et_name>$et_name</td>
				<td>$row[32] $Corp_csname{$row[32]}</td>
				<td>$Settle_date</td>
				<td>$Settle_checkdate</td>
				<td>$Settle_checkman</td>
				<td >$bank_name</td>
				<td align=center><a href="javascript:Show_book('$row[0]');" title='�鿴����'>$Air_date</td>
				<td align=center>$s_city$e_city&nbsp;</td>					
				<td align=center>$row[6]</td>!;
				$temp_id = $row[0];$Res_serial=0;push(@HCityRs,$row[3]);
				$i++;
			}
			else{
				print qq!<tr bgcolor="#ffffff" align=center >!;
				if( $tmp_serial eq $row[5]){	## �Ϻ���
					print "<td height=20 colspan=14>&nbsp</td>";
				}
				else{	## �º���
					$tmp_serial = $row[5];$Res_serial++;push(@HCityRs,$row[3]);
					$Air_date=$row[1];
					print "<td height=20 colspan=11>��</td>";
					print  "<td align=center>$Air_date</td>
						<td align=center>$s_city$e_city&nbsp;</td>
						<td align=center>$row[6]</td>";						
				}
			}
			my $tktno=$a_code."-".$tk_id;
			if ($lid>0) {
				$tktno .="0".$lid;
			}
			print qq`<td>$row[7]</td>
				<td>$tktno</td>
				<td>$scny_price</td>
				<td>$tax</td>
				<td>$in_price</td>`;
			if ($first_row eq "Y") {
				print "<td>$et_price</td><td>$airfare</td>";
				$pay_amount{$row[0]}+=$et_price;
				$Total_count+=$et_price;
			}else{
				print qq!<td>--</td><td>--</td>!;
				$pay_amount{$row[0]}+=0;
			}
			print qq`<td>$payer</td></tr>`;
		
	
			$w ++;
			$order_serial++;
		}
	}
	$total_tmp += $recv;
	$comm_tmp += $comm;

	$out_total = $total_tmp;
	print qq`<tr align='right'><td colspan='17'></td><td colspan='2'>�ϼƣ�</td><td>$Total_count</td></tr>`;
	if ($Find_res > 0){
		
		print qq!</table></span></div><div class="clear"></div>!;
		if (($op == 1 ||$op == 0 ||$op == 3 || $op == 4) && $in{History} ne "Y"){##����ͨ���ͻ���ѯʱ��������������     liangby@2008-6-17
			my $pay_amount_info=Dumper(\%pay_amount);
			$pay_amount_info=~ s/ \=\> /\:/g;$pay_amount_info=~ s/\:undef/\:\'\'/g;
			$pay_amount_info=~ s/\n//g;$pay_amount_info=~ s/ //g;
			$pay_amount_info=~ s/\$VAR1/var pay_amount/;
			print qq`
			<div class="operating" >
				<div class="operating_button">
					<table width="100%" border="0" cellspacing="0" cellpadding="1">
						<tbody>`;
							$t_bt = qq!<label for="cb"><input type="checkbox" name="cb" id="cb" onclick="ck_all();" class="radio_publish"><font style='font-size:9pt;'>ѡ��ȫ��</font></label>!;
							my $bank_display=" style='display:none;' ";
							my $disabled;
							if ($op == 0 ){ ##δ����
								$bank_display="";
								$t_bt .= "�������ͣ�<label><input type=radio name='all_type' value='S' checked class='radio_publish'>��������</label>";
								#$t_bt .= "�������<input type=text name=payamount id=payamount value='0' style='width:70px;'>";
							}
							elsif ($op == 1 ){ ## �Ѹ�������
								$t_bt .= "�������ͣ�<label><input type=radio name='all_type' value='CK' checked class='radio_publish'>�������</label>��";
								$t_bt .= "<label><input type=radio name='all_type' ' value='TK' class='radio_publish' >�����˿�</label>��";
								#$t_bt .= "�������<input type=text name=payamount id=payamount value='0' style='width:70px;' readonly=true >";
							}elsif($op == 3){ ## ҵ�������
								if ( &Binary_switch($Function_ACL{CWFK},0,'A')==0 ){
									$disabled=" disabled=disabled";
								}
								$t_bt .= "�������ͣ�<label><input type=radio name='all_type' value='AK' checked class='radio_publish' >�������</label>��";
							}elsif($op == 4){ ## �������
								if ( $in{Op} eq "4" && (&Binary_switch($Function_ACL{CWFK},1,'A')==0)){
									$disabled=" disabled=disabled";
								}
								$t_bt .= "�������ͣ�<label><input type=radio name='all_type' value='BK' checked class='radio_publish' >�������</label>��";
							}
							print qq`
							<tr>
								<td>
									<table width="100%" border="0" cellspacing="0" cellpadding="2">
										<tbody>
											<tr bgcolor="#f9fafc">
												<td>
													$t_bt
													<span $bank_display>�������<input type=text name=payamount id=payamount value='0' style='width:70px;'> ��������:<select name="pay_by" id='pay_bys' style="width:180px;" $getscript>$bank_list</select> </span>

													<input name="btok" type="button" class="btn30" onclick='amountcomp();' value="ȷ���ύ" $disabled/>
												</td>
												<td>
													&nbsp;
												</td>
											</tr>
										</tbody>
									</table>
								</td>
							</tr>`;
		
							print qq`
						</tbody>
					</table>
				</div>
			</div>
			<input type=hidden name=User_ID value="$in{User_ID}" />
			<input type=hidden name=Serial_no value="$in{Serial_no}" />
			<input type=hidden name=Order_type value="$in{Order_type}" />
			<input type=hidden name=Depart_date value="$Depart_date" />
			<input type=hidden name=End_date value="$End_date" />
			<input type=hidden name=Op value="$in{Op}" />
			<input type=hidden name=Do_act value="W" />
			<input type=hidden name=Start value="1" />
			<input type=hidden name=air_type value="$in{air_type}" />
			<input type=hidden id='Pay_kemu' name=Pay_kemu value='' />
			<input type=hidden name=t_num id="t_num" value="$i" />
			<input type=hidden name=et_type value='$in{et_type}' />
			<input type=hidden name=office_id value='$in{office_id}' />
			<script type="text/javascript">
				var kemulist = [$kemulist];
				$pay_amount_info
				var changeKemu = function(data, type, defaultid)
				{
					var listobj = Fid('pay_bys');
					removeAll(listobj);
					Fid('Pay_kemu').value='$Pay_kemu';
					var defaultselected = '��ѡ��֧������';
					listobj[listobj.options.length] = new Option(defaultselected, '');
					var listnum = 1;
					for (var cityid in data)
					{
						if (type != 'ALL' && type != '' && data[cityid][3].indexOf(type) == -1)
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
				function get_paykemu(){
					var val=Fid('pay_bys').value;
				
					for (var i = 0; i < kemulist.length; i++) {
						if (kemulist[i][1] == val) {
							Fid('Pay_kemu').value=kemulist[i][4];
							break;
						}
					}
				}
				function et_type_st(type){
					if (type == 'B') {	//B2B
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
					}else if (type == 'ALL') {	//ȫ��
						changeKemu(kemulist, 'ALL', '$bank_id');
					}
					else if (type == 'T') {	//B2T
						changeKemu(kemulist, '9', '$bank_id');
					}else if (type == 'Y') {	//BSP
						changeKemu(kemulist, 'a', '$bank_id');
					}
				}
				et_type_st('$in{et_type}');
			</script>`;
			$i_select = join(",",@i_select);
			$i_select = "var i_select = new Array($i_select,0);";

			print qq^<script type="text/javascript">
			document.onkeydown = keyDown;
			document.onkeyup = keyup;
			function keyDown(e){
				if(event.keyCode==16){
					document.book.sh_event.value=1;
				}
			}
			function keyup(e){
				if(event.keyCode==16){
					document.book.sh_event.value=0;
				}
			}
			function Round(a_Num , a_Bit)  {
			  return( Math.round(a_Num * Math.pow (10 , a_Bit)) / Math.pow(10 , a_Bit))  ;
			}  ��
			function hide_all(){
				show('sh');hide('hd');
				$hide_all;
			}
			function show_all(){
				hide('sh');show('hd');
				$show_all;
			}
			$i_select
			$is_lock
			function ck_all(){	
				if ( Fid('t_num').value == 0 ) return; 
				
				if (Fid('cb').checked) {
					for (var j=0; j < i_select.length; j++){
						var cb_obj=Fid('cb_'+j);
						if (cb_obj && cb_obj.disabled==false) {
							cb_obj.checked=true;
							i_select[j]=1;
						}
					}
				}
				else{
					for (var j=0; j < i_select.length; j++){
						var cb_obj=Fid('cb_'+j);
						if (cb_obj && cb_obj.disabled==false) {
							cb_obj.checked=false;
							
						}
					}
					for (var j=0; j < i_select.length; j++){	i_select[j] = 0;	}
				}
				sum_amount();
			}
			function sum_amount(){
				var t_num=Fid('t_num').value;
				var amount=0;
				for (var i=0;i<t_num ;i++) {
					var cb_obj=Fid('cb_'+i);
					if (cb_obj && cb_obj.checked==true) {
						var resid=cb_obj.value;
						amount=(amount*1+pay_amount[resid]*1).toFixed(2);
					}
				}
				Fid('payamount').value=amount;
			}
			function amountcomp(){
				var t_num=Fid('t_num').value;	
				for (var i=0;i<t_num ;i++) {
					var cb_obj=Fid('cb_'+i);
					if (cb_obj && cb_obj.checked==true) {
						var resid=cb_obj.value;
						var et_type=Fid('et_type_'+i).value;
						if(Fid('pay_bys').value==''&&"$op"=="0"&&et_type!="BSP"){
							alert('������һ����ѡ����Ʊ֤����Ϊ��BSP���ͣ���ѡ�񸶿�����');
							return false;
							break;
						}
					}
				}
				var ck_num=0;
				for (var j=0; j < i_select.length-1; j++){
					if (Fid('cb_'+j) && Fid('cb_'+j).checked) {
						ck_num++;			
					}
				}
				if (ck_num==0) {
					alert("��ѡ�񶩵�");
					return false;
				}
				var conret=confirm("ȷ���ύ?");
				if (conret==false) {
					return;
				}
				Fid('book_form').submit();
			}
			</script>^;	
		}
	}else{
		print qq!</table><h3 class="tishi">û�з������������ݡ�</h3></div><div class="clear"></div>!;
	}
	if ($op==1){
		print qq`<script>
			
			var changeKemu1 = function( type )
				{
					var listobj = Fid('pay_bys1');
					removeAll(listobj);
					var defaultselected = '��ѡ��֧������';
					listobj[listobj.options.length] = new Option(defaultselected, '');
					var listnum = 1;
					var data = [$kemulist];
					for (var cityid in data)
					{
						if (type != 'ALL' && type != '' && data[cityid][3].indexOf(type) == -1)
						{
							continue;
						}
						
						listobj[listobj.options.length] = new Option(data[cityid][2], data[cityid][1]);
						if ("$in{pay_by1}" != "" && "$in{pay_by1}" == data[cityid][1] && type == "$in{faketype}" ){
							listobj.options.selectedIndex = listnum;
						}
						if ('$Corp_center' == data[cityid][0]) {
							listobj.options[listnum].style.color = '#0000FF';
						}
						listnum++;
					}
					var i;
					if (!Fid('faketype')){ // ֻ�ڼ���ʱ������ֵ
						i = document.createElement("input");
						i.type = "hidden";
						i.id = "faketype";
						i.name="faketype";
						i.value = type;
						Fid('query').appendChild(i);
					}
				}
		</script>`;
	}
	print qq!</form>!;
	if ($in{down_data} eq "Y") {
		$in{down_data} = "";
		$downdata = "Y";
	}
	if($in{nopaging} eq "Y"){
		print "<table border=0 cellpadding=2 cellspacing=0 width=100% style='display:$dw_hidden'>
			<tr><td>���� $Total_num ��������</td>";		
	}elsif($Total_num > $records) {
		print "<table border=0 cellpadding=2 cellspacing=0 width=100% style='display:$dw_hidden'>
		<tr><td>���� $Total_num ��������</td>
		<td align=right>";
		## ----------------------------- start of page control ----------------------------- 
		my $pageButtons = &showPages_2016($Total_num, $records, $Start, 10, '', 0,'','N');
		##  ----------------------------- end of page control ------------------------------ 
		print "$pageButtons</tr></table>";
		
	}
	##------------------------------------------------------------------------------
	print qq!<br><table border=0 cellpadding=0 cellspacing=0 align=center width="600">!;
	##�������ɱ��
	if ($downdata eq "Y") {
		
		$workbook->close;		
		if ($@=~/$BUF/) {##�������Excelʧ��         
			$BUF="error";
		}
		my $fileName = $BUF;
		$fileName =~ s/^.*(\\|\/)//; #��������ʽȥ�����õ�·�������õ��ļ���
		$downfile = '/Corp_extra/'.$Corp_ID.'/'.$fileName; 
		if ($BUF eq "error"){
			print qq@
			<tr><td>
			<TABLE align="center" height="100%" width=100% border=0 bgcolor=f0f0f0 cellspacing=0 cellpadding=1 >
				<tr><td height=40 align=center><br><font color=red ><b>����Excel�ļ�ʧ�ܣ���!</b></font></td></tr>			
			</table>
			</td></tr>
			@;
		}else{
			print qq~<form action='/cgishell/golden/admin/report/echo_down.pl' name=dd id='dd' method=post >
					 <input type=hidden name=filename value="$fileName" />
					 <input type=hidden name=User_ID value="$in{User_ID}" />
					 <input type=hidden name=Serial_no value="$in{Serial_no}" />
					 </form>
				<iframe id="rfFrame" name="rfFrame" src="" width="0" height="0" frameborder="0"  style="display:none;"></iframe>
				<script language=javascript >
						 Fid('dd').target="rfFrame";
						 Fid('dd').submit();
				</script>
				~;  
		}
	}
	print qq!</table>!;
	##------------------------------------------------------------------------------
}
sub account_recv_sp{
	##��ȡ��ƿ�Ŀ����Ϣ��ϣ��  liangby@2015-6-11
	my %kemu_hash = &get_kemu($Corp_center,"","hash2","","","","assist","N");
	my $update_check_status="Check_status=isnull(Check_status,0)";
	my $opname="����";
	if ($in{all_type} eq "CK") {
		$opname="���";
	}elsif ($in{all_type} eq "TK") {
		$opname="�˿�";
	}elsif ($in{all_type} eq "AK") {
		$opname="ҵ�������";
		$update_check_status .="|1";
	}elsif ($in{all_type} eq "BK") {
		$opname="�������";
		$update_check_status .="|2";
	}
	$op_num=0;

	for ($i=0;$i<$in{t_num};$i++) {
		my	$cb="cb_$i";	my $res_id=$in{$cb};
		#print MessageBox("������ʾ","����$res_id,$in{inc_insure_num},$Corp_center,$in{User_ID},$in{inc_insure_type},$in{pay_method},$in{Serial_no}"); exit;
		
		if ($res_id ne "") {	## ѡ�еĶ���
			$op_num++;
			my $tkt_diff;
			$sql = "select b.User_ID,b.Book_status,b.Agt_total+b.Insure_out+b.Other_fee+isnull(b.Service_fee,0)-b.Recv_total,
					b.Is_reward,b.Corp_ID,b.Ticket_time,b.If_out,b.Air_type,b.Insure_recv,b.Cost_type,Alert_status,
					b.Pay_method,b.Agt_total+b.Insure_out+b.Other_fee+isnull(b.Service_fee,0),b.AAboook_method,b.Userbp,b.Delivery_method,b.Send_date,datediff(day,b.Ticket_time,getdate()),
					b.Old_resid,b.Recv_total,b.Abook_method,b.Tag_str,rtrim(b.Settle_checkman),b.In_total,rtrim(b.Office_ID),rtrim(b.Pay_bank),b.Pay_kemu,b.Settle_date,b.Check_status,b.ET_price
				from ctninfo..Airbook_$Top_corp b
				where b.Sales_ID='$Corp_center' and b.Reservation_ID='$res_id' ";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						($user_id,$old_status,$left_total,$is_reward,$bk_corp,$old_ticket_time,$if_out,$Air_type,$sale_code,
							$Cost_type,$is_refund,$old_pay,$old_agt_total,$comm_method,$Mobile,$old_delivery_method,$cust_pay_date,$tkt_diff,
							$old_resid,$old_recv_total,$pre_pay_by,$old_Tag_str,$old_settle_checkman,$old_intotal,$sp_corp,$old_paybank,$old_paykemu,$old_settle_date,$old_check_status,$old_et_price)=@row;
					}
				}
			}
			if ($old_status ne "S" && $old_status ne "H" && $old_status ne "P") {	
				print MessageBox("������ʾ","�Բ��𣬲��ܶ�δ��Ʊ����$res_id ��������$opname������"); 
				exit;	
			}
			if (($old_paybank ne "" || $old_paybank ne "N") && $old_settle_date ne "" && $in{all_type} eq "S") {
				print MessageBox("������ʾ","�Բ��𣬲��ܶ��Ѹ����$res_id ��������$opname������"); 
				exit;
			}
			## ������
			$sql_upt = "begin transaction sql_insert \n  ";
			my $remark;
			if ($in{all_type} eq "CK") {##��� 
				$remark="��Ӧ������˲���";
				$sql_upt .=qq! update ctninfo..Airbook_$Top_corp set Settle_checkdate=getdate(),Settle_checkman='$in{User_ID}' where Reservation_ID='$res_id' \n!;
			}elsif($in{all_type} eq "TK"){
				$remark="��Ӧ�����˿����,ԭ֧������$in{pay_by}:$kemu_hash{$old_paybank}[0],ԭ������Ŀ$old_paykemu,ԭ������$old_et_price";
				$sql_upt .=qq! update ctninfo..Airbook_$Top_corp set Pay_bank='N',Pay_kemu='',Settle_date=null,Settle_ID=null where Reservation_ID='$res_id' \n!;
			}elsif($in{all_type} eq "AK"){
				if ( &Binary_switch($Function_ACL{CWFK},0,'A')==0 ){
					print MessageBox("������ʾ","�Բ�����û��Ȩ�޶Զ���$res_id ����ҵ������˲�����"); 
					exit;
				}
				$remark="ҵ������˲���"; 
				$sql_upt .=qq! update ctninfo..Airbook_$Top_corp set $update_check_status where Reservation_ID='$res_id' \n!;
			}elsif($in{all_type} eq "BK"){
				if(&Binary_switch($Function_ACL{CWFK},1,'A')==0){
					print MessageBox("������ʾ","�Բ�����û��Ȩ�޶Զ���$res_id ���в�����˲�����"); 
					exit;
				}
				$remark="�������";
				if($logo_path =~ /f/ && ($old_check_status & 1) != 1){ ## ���������ҵ������˱����Ⱦ���ҵ�������
					print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ����ҵ������˲�����"); 
					exit;
				}
			
				$sql_upt .=qq! update ctninfo..Airbook_$Top_corp set $update_check_status where Reservation_ID='$res_id' \n!;
			}else{
				if($logo_path =~ /f/ && $logo_path !~ /g/ && ($old_check_status & 1) != 1){ ## ֻ����ҵ�������
					print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ����ҵ������˲�����"); 
					exit;
				}
				if($logo_path !~ /f/ && $logo_path =~ /g/ && ($old_check_status & 2) != 2){ ## ֻ���ò������
					print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ���в�����˲�����"); 
					exit;
				}
				if($logo_path =~ /f/ && $logo_path =~ /g/ ){ ## ����ҵ������ˡ��������
					if(($old_check_status & 1) != 1){
						print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ����ҵ������˲�����"); 
						exit;
					}
					if(($old_check_status & 2) != 2){
						print MessageBox("������ʾ","�Բ������ȶԶ���$res_id ���в�����˲�����"); 
						exit;
					}
				}
				$remark="��Ӧ�����������,֧������$in{pay_by}:$kemu_hash{$in{pay_by}}[0],������Ŀ$in{Pay_kemu}";
				$sql_upt .=qq! update ctninfo..Airbook_$Top_corp set Pay_bank='$in{pay_by}',Pay_kemu='$in{Pay_kemu}',Settle_date=getdate(),Settle_ID='$in{User_ID}' where Reservation_ID='$res_id' \n!;
				$sql_upt .=qq! update ctninfo..Airbook_$Top_corp set ET_price=$old_intotal where Reservation_ID='$res_id' and ET_price=0 \n!;
#				$t_sql = "select Res_serial,Last_name,In_price+Tax_fee+YQ_fee
#						from ctninfo..Airbook_detail_$Top_corp where Reservation_ID='$res_id' order by Res_serial,Last_name ";
#				$db->ct_execute($t_sql);
#				while($db->ct_results($restype) == CS_SUCCEED) {
#					if($restype==CS_ROW_RESULT)	{
#						while(@row = $db->ct_fetch)	{
#							$sql_upt .= " delete from ctninfo..Airbook_pay_$Top_corp where Reservation_ID='$res_id' and Res_serial=$row[0] and Last_name='$row[1]' and Op_type='a' \n
#							  insert into ctninfo..Airbook_pay_$Top_corp (Reservation_ID,Res_serial,Last_name,Pay_serial,Pay_object,
#													Price_total,Recv_total,Left_total,User_ID,Operate_time,Comment,Corp_ID,Op_type,
#													Ticket_time,Pay_bank,Pay_string,Pay_trans,Sales_ID,Operate_date,Person_num,Pay_status,CID_corp) 
#												select '$res_id',$row[0],'$row[1]',Isnull(max(Pay_serial),0)+1,'$in{pay_by}',
#													$row[2],$row[2],0,'$in{User_ID}',getdate(),'�����������','$Corp_ID','a',
#													getdate(),'$in{Pay_kemu}','','','$Corp_center',convert(char(10),getdate(),102),1,'','$sp_corp'
#												from ctninfo..Airbook_pay_$Top_corp 
#												where Reservation_ID='$res_id' 
#													and Res_serial=$row[0] 
#													and Last_name='$row[1]' \n";
#						}
#					}
#				}
		
			}
			$sql_upt .="insert into ophis..Op_rmk values('$res_id','$Corp_center','$in{User_ID}',getdate(),'4','A','$remark','$Corp_ID') \n";

			$sql_upt .="insert into ctninfo..Res_op values('$res_id','A','$in{User_ID}','A',getdate()) \n";
			#print "<Pre>$sql_upt";
			#exit;
		
			my $Update = 0;
			$db->ct_execute($sql_upt);
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
				$db->ct_execute("Commit Transaction sql_insert");
				#$db->ct_execute("Rollback Transaction sql_insert");
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT) {
						while(@row = $db->ct_fetch) {
						}
					}
				}
				#print qq!<font style='color:blue;font-size:12px;'>�ɹ�$opname</font>!;
				
			}
			else{
				$db->ct_execute("Rollback Transaction sql_insert");
				while($db->ct_results($restype) == CS_SUCCEED) {
					if($restype==CS_ROW_RESULT) {
						while(@row = $db->ct_fetch) {
						}
					}
				}
				print MessageBox("������ʾ","���� $res_id $opname����ʧ��!");
				exit;
			}
				
			
		}
	}
	
	if ($op_num==0) {
		print MessageBox("������ʾ","��ѡ�񶩵�����$opname!");
		exit;
	}
	
}
## =====================================================================
## �������
## =====================================================================
sub air_check{
	local($op)=@_;
	## ---------------------------------------------------------------------
	&show_air_js();

	##��ȡ����Ա��Ϣ  liangby@2016-3-27
	&get_userinfos("","S','O','Y","");
	print qq!
	<table border=1 cellpadding=0 cellspacing=0 width=100% >
	<tr align=center bgcolor=f0f0f0>
		<td>ѡ��</td>
		<td>������</td>
		<td height=19>��Ʊ����</td>
		<td>����</td>
		<td>Ʊ֤��Դ</td>
		<td>Ʊ֤</td>
		<td>�ͻ�</td>
		<td>�ͻ�����</td>
		<td>����Ա</td>
		<td>��Ʊ����</td>
		<td>ȫ����</td>
		<td>���˺�˾</td>
		<td>��Ʊ��˾</td>
		<td>�˿���</td>
		<td>Ʊ��</td>
		<td>������</td>!;
#print qq!<td>����</td>
#		<td>��������</td>
#		<td>SCNY</td>
#		<td>˰</td>
#		<td>�Ͻ���</td>
#		<td>�½���</td>
#		<td>�ϴ���</td>
#		<td>�´���</td>
#		<td>�Ͻ���</td>
#		<td>�½���</td>
#		<td>�ϴ���</td>
#		<td>�´���</td>
#		<td>�ǽ���</td>
#		<td>�ǽ�˰</td>
#		<td>����˰</td>
#		<td>��������</td>
#		<td>ʵ�ռ�</td>!;
	print qq!</tr>!;
	if ($in{datadown} eq "Y") {
		my $iCol=0;
		$worksheet->write_string($iRow,$iCol,"��Ʊ����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"������",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"Ʊ֤��Դ",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"Ʊ֤",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�ͻ�",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�ͻ�����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����Ա",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"��Ʊ����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"ȫ����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"���˺�˾",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"��Ʊ��˾",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�˿���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"Ʊ��",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"������",$format1);$iCol=$iCol+1;
		$worksheet->write_string($iRow,$iCol,"��������",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"ÿ���β�λ",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"��������",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"Ʊ��",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�Ͻ���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�½���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�ϴ���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�´���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�Ͻ���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�½���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�ϴ���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�´���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"SCNY",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����˰",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"ȼ��˰",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�ǽ���",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�ǽ�˰",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����˰",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"��������",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"ʵ�ռ�",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"�����",$format1);$iCol=$iCol+1; 
		$worksheet->write_string($iRow,$iCol,"ͬ�м�",$format1);$iCol=$iCol+1; 
		$iRow=$iRow+1;
	}
	## ---------------------------------------------
	## ���ڼ��
	## ---------------------------------------------
	if(&date_check($Depart_date)==0){
		return "</td><td align=right><font color=red>������ʾ�����鿪ʼ���������Ƿ���ȷ��</td></tr>";
	}
	## =================================================================================
	$where = " FROM ctninfo..Airbook_$Top_corp a,
			ctninfo..Airbook_lines_$Top_corp c,
			ctninfo..Airbook_detail_$Top_corp g,
			ctninfo..Corp_info f,
			ctninfo..Corp_info h";
	$where .="	WHERE a.Reservation_ID = c.Reservation_ID 
			and a.Reservation_ID=g.Reservation_ID 
			and c.Res_serial=g.Res_serial ";
	$where .=" and a.Agent_ID = f.Corp_ID 
			and a.Sales_ID='$Corp_center' 
			and c.Sales_ID='$Corp_center'
			and g.Sales_ID='$Corp_center' 
			and f.Corp_num='$Corp_center' 
			and a.Corp_ID = h.Corp_ID 
			and h.Corp_num='$Corp_center'
			and a.Book_status<>'C' \n";	
	if ($in{Res_ID} ne "") {
		$where .= " and a.Reservation_ID='$in{Res_ID}' ";
	}
	if ($in{air_type} ne "" && $in{air_type} ne "ALL") {
		$where .= " and a.Air_type='$in{air_type}' ";
	}
	if ($Corp_type ne "T") {	$where .= "and a.Agent_ID='$Corp_ID' ";	}
	if ($in{Guest_name} ne "") { $where .= " and g.First_name = '$in{Guest_name}' \n";	}
	if ($in{user_book} ne "") { $where .= " and a.Book_ID = '$in{user_book}' \n";	}
	if (length($in{PNR}) == 5 || length($in{PNR}) == 6) {
		$in{PNR} =~ tr/a-z/A-Z/;
		$where .= " and a.Booking_ref = '$in{PNR}' and a.Book_time >= dateadd(month,-6,getdate()) \n"; 		
	}
	else{
		$where .= "	and a.Ticket_time >= '$Depart_date'
			and a.Ticket_time < '$in{End_date}'\n";
		if ($op == 0){	$where .=" and a.Alert_status='0' and a.Tag_str not like '%��%' \n";}		## �����δ��
		elsif($op==1){	$where .=" and a.Alert_status='0' and a.Tag_str like '%��%' \n";	}		## ������Ѻ�
		elsif($op==2){	$where .=" and a.Alert_status='1' and a.Tag_str not like '%��%' \n"; }           ##��Ʊδ��  likunhua@2009-02-05
		elsif($op==3){	$where .=" and a.Alert_status='1' and a.Tag_str like '%��%' \n"; }            ##��Ʊ�Ѻ�
		elsif($op==4){	$where .=" and a.Alert_status='2' and a.Tag_str not like '%��%' \n"; }           ##��Ʊδ��
		elsif($op==5){	$where .=" and a.Alert_status='2' and a.Tag_str like '%��%' \n"; }            ##��Ʊ�Ѻ� 
		elsif($op==6){	$where .=" and a.Alert_status='3' and a.Tag_str not like '%��%' \n";	}		##���ڵ�δ��
		elsif($op==7){	$where .=" and a.Alert_status='3' and a.Tag_str like '%��%' \n";	}		##���ڵ��Ѻ�
		elsif($op==8){	$where .=" and a.Alert_status='4' and a.Tag_str not like '%��%' \n";	}		##���˵�δ��
		elsif($op==9){	$where .=" and a.Alert_status='4' and a.Tag_str like '%��%' \n";	}		##���˵��Ѻ�
		elsif($op==10){	$where .=" and a.Tag_str not like '%��%' \n";	}		##ȫ��δ��
		elsif($op==11){	$where .=" and a.Tag_str like '%��%' \n";	}		##ȫ���Ѻ�
	}
	if ($in{Corp_ID} ne "") {	$where .= "and a.Corp_ID='$in{Corp_ID}' ";	}
	if ($in{office_id} ne "") {	$where .= "and a.Office_ID='$in{office_id}' ";	}
	if ($in{bank_id} ne "") {	$where .= "and a.Pay_bank='$in{bank_id}' ";	}
	if ($in{Airline_code} ne "") {
		$in{Airline_code} =~ s/\��/\,/g;
		my $Airline_code=join("','",split(',',$in{Airline_code}));
		$where .= "and g.Air_code in('$Airline_code') ";
	}
	if ($in{B_IATA} ne "") {	$where .= "and c.Departure ='$in{B_IATA}' ";	}
	if ($in{E_IATA} ne "") {	
		if (length($in{E_IATA}) == 3) {
			$where .= "and c.Arrival ='$in{E_IATA}' ";	
		}
		else{
			$in{E_IATA} =~ s/��/','/g;	$in{E_IATA} =~ s/,/','/g;
			$where .= "and c.Arrival in ('$in{E_IATA}') ";	
		}		
	}
	if ($in{Airline} ne "") {	$where .= "and c.Flight_no ='$in{Airline}' ";	}
	if ($in{classcode} ne "") {	
		if (length($in{classcode}) == 1) {
			$where .= "and g.Seat_type ='$in{classcode}' ";	
		}
		else{
			$in{classcode} =~ s/��/','/g;	$in{classcode} =~ s/,/','/g;
			$where .= "and g.Seat_type in ('$in{classcode}') ";	
		}	
		
	}
	if ($in{bk_type} ne "") {	$where .= " and a.Book_type='$in{bk_type}' ";	}
	if ($in{tk_type} ne "ALL") {	$where .= " and g.Is_ET='$in{tk_type}' ";	}
	if ($in{corp_level} ne "") {$where .= " and h.Corp_level='$in{corp_level}' ";	}
	if ($in{Insure_no} ne "") {$where .= " and g.Insure_no='$in{Insure_no}' ";	}
	if ($in{book_dept} ne "") {##��������  liangby@2016-3-27
		my ($bcorp,$dept_id)=split/,/,$in{book_dept};
		$where .=" and a.Book_ID in (select User_ID from ctninfo..User_info where Corp_ID='$bcorp' and Dept=$dept_id and Corp_num='$Corp_center' ) \n";
	}
	if ($in{Tkt_num} ne "") {
		my $Tkt_num=sprintf("%.0f",$in{Tkt_num});
		$where .= " and g.Ticket_ID=$Tkt_num \n";
	}
	if ($in{Is_zc} eq "Y") {
		$where .=" and a.Tag_str like '%��%'";
	}
	elsif ($in{Is_zc} eq "F") {
		$where .=" and a.Tag_str like '%��%'";
	}
	elsif ($in{Is_zc} eq "N") {
		$where .=" and a.Tag_str not like '%[�֣�]%'";
	}
	#print $where;
	## ---------------------------------------------------------------------
	print qq`<center><script>	
	function OpenWindow(theURL,winName,features) { 
	  window.open(theURL,winName,features);
	}
	function Show_ban(resid,type){
		if (type=='0') {
			OpenWindow('air_operate_y.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Operate_type=C&Reservation_ID='+resid,'H_'+resid,'resizable,scrollbars,width=680,height=400,left=200,top=200');
		}
		else if (type=='1' || type=='2') {
			OpenWindow('air_refund_y.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Operate_type=C&ID='+resid,'H_'+resid,'resizable,scrollbars,width=680,height=400,left=200,top=200');
		}
		else if (type=='3') {
			OpenWindow('air_moddate_y.pl?User_ID=$in{User_ID}&Serial_no=$in{Serial_no}&Operate_type=C&ID='+resid,'H_'+resid,'resizable,scrollbars,width=680,height=400,left=200,top=200');
		}
	}
	</script>
	$Header`;
	#select Res_ID,User_ID,right(convert(char(10),Op_time,102),10) + ' '+ convert(char(8),Op_time,108),
	$sql="";
	## ----------------------------------------------------------------------------
	my %office_hash = &get_office($Corp_office,"","hash","A");
	my %tkt_hash=&get_dict($Corp_center,3,"","hash");
	$sql ="select a.Reservation_ID into #tempdata \n ";
	$sql .= $where;
	$sql .="\n group by a.Reservation_ID \n ";
	$sql .="select rtrim(a.Reservation_ID),rtrim(a.Booking_ref),a.Agent_ID,f.Corp_csname,a.Corp_ID,h.Corp_csname,			--5
		rtrim(h.Corp_level),convert(char(10),a.Ticket_time,102),c.Departure,c.Arrival,c.Airline_ID,g.Air_code,				--11
		rtrim(a.Office_ID),rtrim(g.Is_ET),isnull(a.Tkt_num,0),c.Res_serial,g.Last_name,a.Tag_str,a.Alert_status,			--18
		convert(varchar(10),c.Air_date,102),g.Seat_type,isnull(g.Prize_price,0),isnull(g.In_discount,0),isnull(g.In_aft_discount,0),				--23
		isnull(g.Agt_aft_discount,0),isnull(g.Prize_tax,0),isnull(g.Agt_discount,0),g.In_disrate,isnull(g.SCNY_price,0),	--28
		g.Agt_disrate,a.Air_type,g.First_name,isnull(g.Tax_fee,0),isnull(In_tax,0)+isnull(In_yq,0),isnull(In_fee,0),g.Origin_price	--35
		,g.Out_price,a.Book_ID,g.Ticket_ID,isnull(g.Service_fee,0),isnull(g.YQ_fee,0)	--40
		from ctninfo..Airbook_$Top_corp a,
			ctninfo..Airbook_lines_$Top_corp c,
			ctninfo..Airbook_detail_$Top_corp g,
			ctninfo..Corp_info f,
			ctninfo..Corp_info h,
			#tempdata w
		where a.Reservation_ID = c.Reservation_ID
			and a.Reservation_ID=g.Reservation_ID
			and a.Reservation_ID=w.Reservation_ID
			and c.Res_serial=g.Res_serial
			and a.Agent_ID = f.Corp_ID
			and a.Sales_ID='$Corp_center'
			and c.Sales_ID='$Corp_center'
			and g.Sales_ID='$Corp_center'
			and f.Corp_num='$Corp_center'
			and a.Corp_ID = h.Corp_ID
			and h.Corp_num='$Corp_center'
			and a.Book_status<>'C' \n";
	if ($in{Order_type}==1) {
		$sql .= "\n order by a.Corp_ID,a.Reservation_ID,c.Res_serial,g.Last_name \n"; 
	}
	else {
		$sql .= "\n order by a.Ticket_time,a.Reservation_ID,c.Res_serial,g.Last_name \n"; 
	}
	$sql .= "\n drop table #tempdata \n"; 
	#print "<pre>$sql</pre>";
	my @tempdata=();my %airdata=();$Dec_round = "%0.2f";
	$db->ct_execute($sql);
	while($db->ct_results($restype) == CS_SUCCEED) {
		if ($restype==CS_ROW_RESULT)	{
			while(@row = $db->ct_fetch)	{
				my $Air_type=$row[30];
				my $Air_date=$row[19];
				my $Seat_type=$row[20];
				##�˼����ͼ۸���Ϣ
				my $Prize_tax=sprintf("$Dec_round",$row[25]);
				my $In_aft_discount=sprintf("%.4f",$row[23]);		##���ν�������
				my $Prize_price=sprintf("$Dec_round",$row[21]);		
				my $In_discount=sprintf("$Dec_round",$row[22]);		##�ϴ���
				my $Agt_discount=sprintf("$Dec_round",$row[26]);	##�´���
				my $Agt_aft_discount=sprintf("%.4f",$row[24]);		##���ν�������
				my $In_aft_Prizetax=sprintf("$Dec_round",($Prize_tax*$In_aft_discount/100));
				my $Agt_aft_Prizetax=sprintf("$Dec_round",($Prize_tax*$Agt_aft_discount/100));
				my $Hs_profit=sprintf("$Dec_round",$Prize_price*(1-$In_discount/100)*$In_aft_discount/100+$In_aft_Prizetax+0.00001);#���ν���
				my $Xs_profit=sprintf("$Dec_round",$Prize_price*(1-$Agt_discount/100)*$Agt_aft_discount/100+$Agt_aft_Prizetax+0.00001);#���ν���
				my $In_discount_price=sprintf("$Dec_round",$row[27]);	##�ϴ���
				my $Agt_discount_price=sprintf("$Dec_round",$row[29]);	##�´���
				my $SCNY_price=sprintf("$Dec_round",$row[28]);		
				my $Out_price=sprintf("$Dec_round",$row[36]);		##����
				if ($In_discount_price>0 && $SCNY_price!=0) {
					$In_discount=sprintf("$Dec_round",($In_discount_price/$SCNY_price)*100);
				}
				if ($In_discount_price==0 && $In_discount>0 && $SCNY_price!=0) {
					$In_discount_price=sprintf("$Dec_round",($In_discount/100)*$SCNY_price);
				}
				if ($Agt_discount_price>0 && $SCNY_price!=0) {
					$Agt_discount=sprintf("$Dec_round",($Agt_discount_price/$SCNY_price)*100);
				}
				if ($Agt_discount_price==0 && $Agt_discount>0 && $SCNY_price!=0) {
					$Agt_discount_price=sprintf("$Dec_round",($Agt_discount/100)*$SCNY_price);
				}
				if ($airdata{$row[0]}{resid} eq "") {
					push(@tempdata,[@row]);
					$airdata{$row[0]}{resid}=$row[0];
				}
				push(@tempdata_ex,[@row]);
				$airdata{$row[0]}{air_type}=$Air_type;
				if ($row[16]==0) {
					if ($airdata{$row[0]}{voyage} ne "") {$airdata{$row[0]}{voyage}.='/';}
					$airdata{$row[0]}{voyage}.="$row[8]-$row[9]";
					if ($airdata{$row[0]}{airline} ne "") {$airdata{$row[0]}{airline}.='/';}
					$airdata{$row[0]}{airline}.=$row[10];
					if ($airdata{$row[0]}{air_date} ne "") {$airdata{$row[0]}{air_date}.='/';}
					$airdata{$row[0]}{air_date}.=$Air_date;
					if ($airdata{$row[0]}{seat_type} ne "") {$airdata{$row[0]}{seat_type}.='/';}
					$airdata{$row[0]}{seat_type}.=$Seat_type;	
					if ($airdata{$row[0]}{in_aft_discount} ne "") {$airdata{$row[0]}{in_aft_discount}.='/';}
					$airdata{$row[0]}{in_aft_discount}.=$In_aft_discount;
					if ($airdata{$row[0]}{agt_aft_discount} ne "") {$airdata{$row[0]}{agt_aft_discount}.='/';}
					$airdata{$row[0]}{agt_aft_discount}.=$Agt_aft_discount;
					if ($airdata{$row[0]}{hs_profit} ne "") {$airdata{$row[0]}{hs_profit}.='/';}
					$airdata{$row[0]}{hs_profit}.=$Hs_profit;
					if ($airdata{$row[0]}{xs_profit} ne "") {$airdata{$row[0]}{xs_profit}.='/';}
					$airdata{$row[0]}{xs_profit}.=$Xs_profit;
					if ($airdata{$row[0]}{in_discount} ne "") {$airdata{$row[0]}{in_discount}.='/';}
					$airdata{$row[0]}{in_discount}.=$In_discount;
					if ($airdata{$row[0]}{agt_discount} ne "") {$airdata{$row[0]}{agt_discount}.='/';}
					$airdata{$row[0]}{agt_discount}.=$Agt_discount;
					if ($airdata{$row[0]}{in_discount_price} ne "") {$airdata{$row[0]}{in_discount_price}.='/';}
					$airdata{$row[0]}{in_discount_price}.=$In_discount_price;
					if ($airdata{$row[0]}{agt_discount_price} ne "") {$airdata{$row[0]}{agt_discount_price}.='/';}
					$airdata{$row[0]}{agt_discount_price}.=$Agt_discount_price;
					
					$airdata{$row[0]}{serial_num}++;
				}
				if ($row[15]==0) {
					$airdata{$row[0]}{detail_num}++;
				}
			}
		}
	}
	my $Total_num=scalar(@tempdata);
	my $Find_res = 1;
	my $records = $in{perpage} eq '' ? 20 : $in{perpage};
	if ($in{Start} eq "") { $Start=1;	} else {	$Start=$in{Start};	}
	my $t_records = $Start * $records;
	my ($tkt_sum,$serial_num,$detail_num)=(0,0,0);
	$n_bk=0;
	##����ͳ��
	my ($d_tkt_sum,$d_serial_num,$d_detail_num)=(0,0,0);
	$d_bk=0;	
	my @sj_rate=();@xj_rate=();@sd_rate=();@xd_rate=();
	my $res_id_extag="";
	my $voyage_extag="";
	for (my $k=0;$k<$Total_num ;$k++) {
		my @row=@{$tempdata[$k]};
		#print "$_"."|" for @row;
		#print "<br>------------------------------------------------------<br>";
		if($Find_res<=$t_records && $Find_res>($Start-1)*$records ){
			my $cbdisabled=($row[17]=~/��/)?"disabled":"";
			my $pnr=$row[1];	
			if ($pnr eq "") {	$pnr="-----";	}
			else{
				$pnr = qq!<a href="javascript:Show_pnr('$row[0]','$pnr');" title='��ȡ����'>$pnr</a>!;
			}
			if ($row[0] eq $res_id_tag) {
				#print qq!
				#<tr align=center><td colspan=15></td>!;
			}else{
				#����
				@sj_rate = split /\//,$airdata{$row[0]}{in_aft_discount};
				@xj_rate = split /\//,$airdata{$row[0]}{agt_aft_discount};
				@sd_rate = split /\//,$airdata{$row[0]}{in_discount};
				@xd_rate = split /\//,$airdata{$row[0]}{agt_discount};

				#����
				@sj_fee = split /\//,$airdata{$row[0]}{hs_profit};
				@xj_fee = split /\//,$airdata{$row[0]}{xs_profit};
				@sd_fee = split /\//,$airdata{$row[0]}{in_discount_price};
				@xd_fee = split /\//,$airdata{$row[0]}{agt_discount_price};

				$i = 0;
				print qq!
				<tr align=center>
					<td height=20><input type="Checkbox" name="cb_$k" value="$row[0]" $cbdisabled></td>
					<td><a href="javascript:Show_ban('$row[0]',$row[18]);" title='�������'>$row[0]</a></td>
					<td><a href="javascript:Show_book('$row[0]');" title='�鿴����'>$row[3]</a></td>
					<td>$pnr</td>
					<td>$office_hash{$row[12]}</td>
					<td>$tkt_hash{$row[13]}</td>
					<td>$row[5]</td>
					<td>$Corp_level_name{$row[6]}</td>
					<td>$USER_NAME{$row[37]}[1]</td>
					<td>$row[7]</td>
					<td align=left>$airdata{$row[0]}{voyage}</td>
					<td align=left>$airdata{$row[0]}{airline}</td>
					<td>$row[11]</td>
					<td>$airdata{$row[0]}{detail_num}</td>
					<td>$row[14]</td>
					<td>$airdata{$row[0]}{serial_num}</td>!;
				$res_id_tag = $row[0];
				$tkt_sum+=$airdata{$row[0]}{detail_num};
				$serial_num+=$row[14];
				$detail_num+=$airdata{$row[0]}{serial_num};
				$n_bk++;
			}
#			if ("$row[8]-$row[9]" eq $voyage_tag) {
				#print qq!<td></td>!;
#			}else{
				#print qq!<td align=left>$row[8]-$row[9]</td>!;
				#$voyage_tag = "$row[8]-$row[9]";
#			}
#			print qq!<td align=left>$row[31]</td>
#					<td align=left>$row[28]</td>
#					<td align=left>$row[32]</td>!;
#			print qq!<td align=left>$sj_rate[$i]</td>
#					<td align=left>$xj_rate[$i]</td>
#					<td align=left>$sd_rate[$i]</td>
#					<td align=left>$xd_rate[$i]</td>!;
#			print qq!<td align=left>$sj_fee[$i]</td>
#					<td align=left>$xj_fee[$i]</td>
#					<td align=left>$sd_fee[$i]</td>
#					<td align=left>$xd_fee[$i]</td>!;
#			$row[21] = sprintf("$Dec_round",$row[21]);
#			$row[25] = sprintf("$Dec_round",$row[25]);
#			print qq!<td align=left>$row[21]</td>
#					<td align=left>$row[25]</td>
#					<td align=left>$row[33]</td>
#					<td align=left>$row[34]</td>
#					<td align=left>$row[35]</td>!;
			print qq!</tr>!;
			
			$sj_fee_total += $sj_fee[$i];
			$xj_fee_total += $xj_fee[$i];
			$sd_fee_total += $sd_fee[$i];
			$xd_fee_total += $xd_fee[$i];

			$SCNY_total += $row[28];
			$Tax_total += $row[32];
			$Prize_total += $row[21];
			$Prize_tax_total += $row[25];
			$In_tax_total += $row[33];
			$In_fee_total += $row[34];
			$Origin_total += $row[35];
		}
		$Find_res ++;
	}

	if ($n_bk>0) {
		print qq!
		<tr align=right>
			<td height=20 colspan=13><b>�ܼƣ����� $n_bk ������</td>
			<td align=center>$tkt_sum</td>
			<td align=center>$serial_num</td>
			<td align=center>$detail_num</td>!;
#		print qq!<td align=center colspan=2></td>
#			<td align=center>$SCNY_total</td>
#			<td align=center>$Tax_total</td>
#			<td align=center colspan=4></td>
#			<td align=center>$sj_fee_total</td>
#			<td align=center>$xj_fee_total</td>
#			<td align=center>$sd_fee_total</td>
#			<td align=center>$xd_fee_total</td>
#			<td align=center>$Prize_total</td>
#			<td align=center>$Prize_tax_total</td>
#			<td align=center>$In_tax_total</td>
#			<td align=center>$In_fee_total</td>
#			<td align=center>$Origin_total</td>!;
		print qq!</tr>!;
	}
	else{
		print "<tr><td height=20 colspan=15><font color=red>ϵͳ��ʾ��û�з������������ݡ�</td></tr>";
	}
	print "</table>";
	$pageButtons = &showPages($Total_num, $records, $Start, 10, '', 2);
	my $i = 0;
	my $Total_num_ex=scalar(@tempdata_ex);
	if ($in{datadown} eq "Y") {
		for (my $k=0;$k<$Total_num_ex ;$k++) {
			my @row=@{$tempdata_ex[$k]};
			$iCol=0;
			if ($row[0] ne $res_id_extag) {
				$worksheet->write_string($iRow,$iCol,"$row[2] $row[3]",$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$row[1],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$row[0],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$office_hash{$row[12]},$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$tkt_hash{$row[13]},$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,"$row[4] $row[5]",$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$Corp_level_name{$row[6]},$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$USER_NAME{$row[37]}[1],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$row[7],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$airdata{$row[0]}{voyage},$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$airdata{$row[0]}{airline},$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$row[11],$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$airdata{$row[0]}{detail_num},$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$row[14],$format1);	$iCol=$iCol+1;
				$worksheet->write_number($iRow,$iCol,$airdata{$row[0]}{serial_num},$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$airdata{$row[0]}{air_date},$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$airdata{$row[0]}{seat_type},$format1);	$iCol=$iCol+1;
				$res_id_extag = $row[0];
				$d_tkt_sum+=$airdata{$row[0]}{detail_num};
				$d_serial_num+=$row[14];
				$d_detail_num+=$airdata{$row[0]}{serial_num};
				$d_bk++;
				$i = 0;
			}else{
				$iCol=17;
			}
			
			if ($voyage_extag ne "$row[8]-$row[9]") {
				$worksheet->write_string($iRow,$iCol,"$row[8]-$row[9]",$format1);	$iCol=$iCol+1;
				$voyage_extag = "$row[8]-$row[9]";
				$i = 0;
			}else{
				$iCol++;
			}
			#����
			@sj_rate = split /\//,$airdata{$row[0]}{in_aft_discount};
			@xj_rate = split /\//,$airdata{$row[0]}{agt_aft_discount};
			@sd_rate = split /\//,$airdata{$row[0]}{in_discount};
			@xd_rate = split /\//,$airdata{$row[0]}{agt_discount};
			#����
			@sj_fee = split /\//,$airdata{$row[0]}{hs_profit};
			@xj_fee = split /\//,$airdata{$row[0]}{xs_profit};
			@sd_fee = split /\//,$airdata{$row[0]}{in_discount_price};
			@xd_fee = split /\//,$airdata{$row[0]}{agt_discount_price};

			$worksheet->write_string($iRow,$iCol,$row[31],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[38],$format1);	$iCol=$iCol+1;
			#if($airdata{$row[0]}{air_type} eq "Y"){		##������ʾ���ʣ�������ʾ����
				$worksheet->write_string($iRow,$iCol,$sj_rate[$i],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$xj_rate[$i],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$sd_rate[$i],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$xd_rate[$i],$format1);	$iCol=$iCol+1;
			#}else{
				$worksheet->write_string($iRow,$iCol,$sj_fee[$i],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$xj_fee[$i],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$sd_fee[$i],$format1);	$iCol=$iCol+1;
				$worksheet->write_string($iRow,$iCol,$xd_fee[$i],$format1);	$iCol=$iCol+1;
			#}
			$Actual_price = $row[35]+$row[32]+$row[40]+$row[39];
			$Offer_price = $row[36]+$row[32]+$row[40]+$row[39];
			$worksheet->write_string($iRow,$iCol,$row[28],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[32],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[40],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[21],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[25],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[33],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[34],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$Actual_price,$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$Offer_price,$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[39],$format1);	$iCol=$iCol+1;
			$worksheet->write_string($iRow,$iCol,$row[35],$format1);	$iCol=$iCol+1;
			
			$sj_fee_total_ex = $sj_fee[$i];
			$xj_fee_total_ex = $xj_fee[$i];
			$sd_fee_total_ex = $sd_fee[$i];
			$xd_fee_total_ex = $xd_fee[$i];

			$SCNY_total_ex += $row[28];
			$Tax_total_ex += $row[32];
			$YQ_total_ex += $row[40];
			$Prize_total_ex += $row[21];
			$Prize_tax_total_ex += $row[25];
			$In_tax_total_ex += $row[33];
			$In_fee_total_ex += $row[34];
			$Origin_total_ex += $row[35];
			$Out_total_ex += $row[36];
			$Service_fee_total_ex += $row[39];
			$Actual_total_ex += $Actual_price;
			$Offer_total_ex += $Offer_price;

			$iRow=$iRow+1;
			$i++;
		}
	}

	if ($in{datadown} eq "Y" && $d_bk > 0) {
		$iCol=11;
		$worksheet->merge_range($iRow,0,$iRow,$iCol,"�ܼƣ����� $d_bk �ţ���",$format3);$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$d_tkt_sum,$format1);		$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$d_serial_num,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$d_detail_num,$format1);	$iCol=$iCol+1;
		$iCol +=9;
		$worksheet->write_number($iRow,$iCol,$sj_fee_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$xj_fee_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$sd_fee_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$xd_fee_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$SCNY_total_ex,$format1);		$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$Tax_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$YQ_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$Prize_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$Prize_tax_total_ex,$format1);		$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$In_tax_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$In_fee_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$Actual_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$Offer_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$Service_fee_total_ex,$format1);	$iCol=$iCol+1;
		$worksheet->write_number($iRow,$iCol,$Origin_total_ex,$format1);	$iCol=$iCol+1;
		$iRow=$iRow+1;
	}
}

## �հ׵��ܾ�����  linjw@2016-11-18
sub refuse_pay_op {
	local($res_id)=@_;
	my $Update = 0;
	$sql_upt="update ctninfo..Inc_book set Book_status='W',User_rmk='$in{refuse_remark}',Ticket_by=null,Ticket_date=null where Res_ID='$res_id'";
#	print "<pre>$sql_upt";
#	exit;
	$db->ct_execute($sql_upt);
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
		$db->ct_execute("Commit Transaction sql_insert");
		#$db->ct_execute("Rollback Transaction sql_insert");
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
				}
			}
		}
		return "<font color='blue'>$res_id�ܾ�����ɹ���</font></br>";
	}
	else{
		$db->ct_execute("Rollback Transaction sql_insert");
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT) {
				while(@row = $db->ct_fetch) {
				}
			}
		}
		return "<font color='red'>$res_id�ܾ�����ʧ�ܣ�</font></br>";
	}
}

##���߻��ɹ�Ӧ�����ɹ����Զ���ֵ  linjw@2017-12-05
sub pt_auto_balance{
	local($resid_corp_s,$resid_amount_s)=@_;
	my %resid_corp_s=%{$resid_corp_s};
	my %resid_amount_s=%{$resid_amount_s};
	my %pt_corps=();		##�ɹ���cid-���߿�id
	my %pt_amount=();		##�ɹ���cid-�������
	foreach my $resid (keys(%resid_corp_s)) {
		##���ɹ�Ӧ����
		my $pt_resid="";
		my $sql="select Reservation_ID from ctninfo..Supply_Records where Corp_Num='$Corp_center' and PT_ID='SKY029' and Reservation_ID='$resid' \n";
		#print "<pre>$sql";
		$db->ct_execute($sql);
		while($db->ct_results($restype) == CS_SUCCEED) {
			if($restype==CS_ROW_RESULT)	{
				while(@row = $db->ct_fetch)	{
					$pt_resid=$row[0];
				}
			}
		}
		if($pt_resid ne ""){
			##��ѯ����cid�Ƿ���ɹ��̰�
			my $pt_corp=$resid_corp_s{$pt_resid};
			$sql=" select rtrim(Corp_ID),Pcorp from ctninfo..Corp_partner where Corp_num='$Corp_center' and Partner='B' and Corp_ID='$pt_corp' ";
			#print "<pre>$sql";
			$db->ct_execute($sql);
			while($db->ct_results($restype) == CS_SUCCEED) {
				if($restype==CS_ROW_RESULT)	{
					while(@row = $db->ct_fetch)	{
						$pt_corps{$row[0]}=$row[1];
						$pt_amount{$row[0]}+=$resid_amount_s{$pt_resid};
					}
				}
			}
		}
	}
	
	my @pt_corps=sort keys(%pt_corps);
	if(scalar(@pt_corps) > 0){
		foreach my $cid (@pt_corps) {
			my %para_str=(
				"corp_id"=>"$Corp_center",
				"user_id"=>"$in{User_ID}",	
				"bk_corp"=>"$cid",
				"pt_corp"=>"$pt_corps{$cid}",
				"pt_ammount"=>"$pt_amount{$cid}",
				"t_type"=>"8"
			);
			my @param_key=sort keys %para_str;
			my $en_str;
			my $pt_param;
			for (my $i=0;$i<scalar(@param_key) ;$i++) {
				if ($pt_param ne "") {
					$pt_param .="&";
				}
				if ($en_str  ne "") {
					$en_str .="&";
				}
				$en_str .=$param_key[$i]."=".$para_str{$param_key[$i]};
				$pt_param .=$param_key[$i]."=".$para_str{$param_key[$i]};
			}
			
			##md5ǩ��
			$md5_key='Dh#K!fa$H';
			$en_str .=$md5_key;
			$context = new MD5;
			$context->reset();
			$context->add($en_str);
			$md5_str = $context->hexdigest;
			$md5_str=~tr/[a-z]/[A-Z]/;
			$pt_param.="&Sign=$md5_str";
			my $pt_url="http://$G_SERVER/cgishell/golden/admin/airline/res/PT_order_update.pl";
			my $pt_sql="BEGIN Transaction sql_insert \n
				insert into ctninfo..Echo_time_plan(Sales_ID,S_url,S_param,S_type,S_status,Op_time,Send_count,Time_type,Q_type) 
							values('$Corp_center','$pt_url','$pt_param','2','0',getdate(),0,'0','J') ";
			$Update=&write_to_db($pt_sql,"N");
			if ($Update==0) {
				&write_log_test("$Corp_center|$cidд������ʧ��:$sql");
			}
		}
	}
}

sub write_log_account{
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
	if (! -e $log_path) {#Ŀ¼������
		 mkdir($log_path,0002);
	}elsif(!-d $log_path){#�����ļ�������Ŀ¼
		 mkdir($log_path,0002);
	}
	$log_path .="/lib/";
	if (! -e $log_path) {#Ŀ¼������
		 mkdir($log_path,0002);
	}elsif(!-d $log_path){#�����ļ�������Ŀ¼
		 mkdir($log_path,0002);
	}
	$filename=">> $log_path"."air_account_$file_date.log";
	open MAIL,"$filename" || die "���󣺲��ܴ��ļ�";
	print MAIL "----------------------$today2" || die "error"; 
	print MAIL "$s_msg \n";
	close(MAIL);
}

1;