#!/usr/local/bin/perl
use strict;
use utf8;
use DBI;	#DBD::Oracle
use Data::Dumper;
use Getopt::Long;

#--db      SID
#--password password
#--user  username
#--host hostname[localhost]
#--port listener port [1521]

my %opts=(host=>"localhost",port=>"1521");
GetOptions(\%opts,'db=s','password=s','user=s','host=s','port=s','table=s');
#check option
if(!$opts{db} || !$opts{password} || !$opts{user}){
	print "[ERROR] Check Options\n";
	&HelpSTD;
	exit;
}

my $DB_CONF =
    {host=>	$opts{host},
     port=>	$opts{port},
     db_name=>	$opts{db},
     db_user=>	$opts{user},
     db_pass=>	$opts{password},
    };
my $DBH;

Main();
#option help
sub HelpSTD{
	print "--db  SID[dafault none]\n--user username[default none]\n--password user's password[default none]\n";
	print "--host hostname or IP[default localhost]\n--port listener port[default 1521]\n";
	print "--table tablename if you want to check only one table[dafault none]\n";
}
#main
sub Main{
	$DBH = connect_db();
	&ChkIdx($opts{table}) if($opts{table});
	exit if($opts{table});
	my $sql =<<EOF;
	select TABLE_NAME from user_tables where TABLE_NAME not like 'BIN\$%' order by 1 
EOF
	my $sth = $DBH->prepare($sql);
 	$sth->execute;
	#Loop each tables
	while( my $row = $sth->fetchrow_hashref)
	{
		&ChkIdx($row ->{TABLE_NAME});
	}
	$sth->finish();
}
#index check
sub ChkIdx{
	my $tblnm=shift;
	my $sql=<<EOF;
select * from 
	(select INDEX_NAME
	,listagg(COLUMN_NAME,',') WITHIN GROUP (order by COLUMN_POSITION) as aa
	,row_number() over (order by max(COLUMN_POSITION)) as rn 
	from user_ind_columns where table_name = ? group by INDEX_NAME
) order by rn
EOF
	my $sth= $DBH->prepare($sql);
	$sth->execute($tblnm);
	my $idx_cols;
	my $num_idx;
	#Loop Indexes at the table
	while( my ($idx,$collist,$num) = $sth->fetchrow)
	{
		#put index and column at hash
		$idx_cols->{$idx}=$collist;
		$num_idx->{$num}=$idx;
   	}
	my $cntkey=scalar(keys(%$num_idx));
	my $stdlists="";
	#LOOP the number of indexes at the table
	for(my $ii=1; $ii<=$cntkey;$ii++)
	{
		#LOOP the number of indexes at the table
		for(my $a=1; $a<=$cntkey;$a++)
		{
			#next if already compared
			next if($ii>$a);
			#next if it compares the same index
			next if($num_idx->{$ii} eq $num_idx->{$a});
			$_=$idx_cols->{$num_idx->{$a}};
			next if(! /^$idx_cols->{$num_idx->{$ii}},/);
			$stdlists=$stdlists.&MkStd($num_idx->{$a},$idx_cols->{$num_idx->{$a}});
			
		}
		#check PK(main loop) 
		if($stdlists)
		{
			my $c=&ChkPK($num_idx->{$ii},$tblnm);
			if($c)
			{
				$stdlists="";
				next;
			}
		}
		&Stdout_IdxInfo($num_idx->{$ii},$idx_cols->{$num_idx->{$ii}},$tblnm,$stdlists) if($stdlists);
		$stdlists="";
	}
}
sub MkStd{
	my $idx=shift;
	my $cols=shift;
	my $st=sprintf("          index: %-30s columns: %s\n",$idx,$cols);
	return $st;
}
sub ChkPK {
	my $dpidx=shift;
	my $tblnm=shift;
	my $pk;
	my $sql=<<EOF;
select CONSTRAINT_NAME from USER_CONSTRAINTS where CONSTRAINT_NAME = ? and TABLE_NAME= ?
EOF
	my $sth= $DBH->prepare($sql);
    	$sth->execute($dpidx,$tblnm);
    	while( my $row = $sth->fetchrow_hashref)
    	{
		 $pk=$row ->{CONSTRAINT_NAME};
    	}	 
	return 0 if(!$pk);
	return 1;
}

sub Stdout_IdxInfo{
	my $dpidx=shift;
	my $dpcols=shift;
	my $tblnm=shift;
	my $stdlists=shift;
	print "\n------------------------------------------------------------------------------------------"."\n";
	print "drop_recommend: DROP INDEX ".$dpidx."\n";
	print "tablename: ".$tblnm."\n";
	print sprintf("duplicate_index: %-30s columns: %s\n",$dpidx,$dpcols);
	print $stdlists; 
}

sub connect_db {

    my $db = join(';',"dbi:Oracle:host=$DB_CONF->{host}","sid=$DB_CONF->{db_name}","port=$DB_CONF->{port}");
    my $db_uid_passwd = "$DB_CONF->{db_user}/$DB_CONF->{db_pass}";
    my $DBH = DBI->connect($db, $db_uid_passwd, "");
    return $DBH;
}

