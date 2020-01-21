#----------------------------------------------------------------------------
# Note: Description
# InitClearQuestFile contains  functions and public strings for clear quest generation.
#----------------------------------------------------------------------------
package InitClearQuestFile;

use strict;
use TestUtil;

my $DEBUG = 0;

our %changeResquestRow = (
	"product",                {libelle => "product",                position => 1,  default_value => "ICONIS_ATS_KE",                        component_property => ""},
	"headline",               {libelle => "headline",               position => 2,  default_value => "",                                       component_property => ""},
	"analyst",                {libelle => "analyst",                position => 3,  default_value => "unknown",                                 component_property => "owner"},
	"submitter",              {libelle => "submitter",              position => 4,  default_value => "guillaume_daunes-ext",                   component_property => ""},
	"key_requirements",       {libelle => "key_requirements",       position => 5,  default_value => "Code Review",                            component_property => ""},
	"defect_detection_phase", {libelle => "defect_detection_phase", position => 6,  default_value => "Detailed Design",                        component_property => ""},
	"severity",               {libelle => "severity",               position => 7,  default_value => "Bypassing",                              component_property => ""},
	"priority",               {libelle => "priority",               position => 8,  default_value => "Medium",                                 component_property => ""},
	"frequency",              {libelle => "frequency",              position => 9,  default_value => "Every Time",                             component_property => ""},
	"product_version",        {libelle => "product_version",        position => 10, default_value => "ICONIS_ATS KERNEL EXTENDED",			component_property => ""},
	"site",                   {libelle => "site",                   position => 11, default_value => "ICONIS ATS DEV -- ICONIS_ATS_KE",		component_property => ""},
	"State",                  {libelle => "State",                  position => 12, default_value => "Recorded",                              component_property => ""},
	"substate",               {libelle => "substate",               position => 13, default_value => "new",                                    component_property => ""},
	"submitter_CR_type",      {libelle => "submitter_CR_type",      position => 14, default_value => "Defect",                                 component_property => ""},
	"submitter_severity",     {libelle => "submitter_severity",     position => 15, default_value => "Bypassing",                              component_property => ""},
	"submitter_priority",     {libelle => "submitter_priority",     position => 16, default_value => "Medium",                                 component_property => ""},
	"CR_type",                {libelle => "CR_type",                position => 17, default_value => "Defect",                                 component_property => ""},
	"customer_access",        {libelle => "customer_access",        position => 18, default_value => "ProductAccess",							component_property => ""},
	"description",            {libelle => "description",            position => 19, default_value => "unknown",									component_property => ""},
	"sub_system",             {libelle => "sub_system",             position => 20, default_value => "unknown",									component_property => "sub_system"},
	"component",              {libelle => "component",              position => 21, default_value => "unknown",									component_property => "component"},
	"CR_category",            {libelle => "CR_category",            position => 22, default_value => "Internal",								component_property => ""},
);

our %componentProperties = (
	"AE_Interface",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "AE Interface", owner =>"" },
	"AO_SCMA",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "AO Interface", owner =>"" },
	"ARS_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "ARST Interface", owner =>"" },
	"ATR_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "ATR Interface", owner =>"" },
	"BasicPTIBuilder",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "Basic PTI Builder", owner =>"" },
	"BasicPTIBuilder_Interface",	{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "Basic PTI Builder Interface", owner =>"" },
	"CBIS_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "CBIS Interface", owner =>"" },
	"CCM_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "CMM Interface", owner =>"" },
	"CCS_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "CCS Interface", owner =>"" },
	"COMMON-FEP-UE",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "COMMON-FEP-UE", owner =>"" },
	"COT",				{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "COT", owner =>"" },
	"COT_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "COT Interface", owner =>"" },
	"CPL_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "CPL Interface", owner =>"" },
	"Common",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "Common", owner =>"" },
	"Common_FEP_Amsterdam",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "Common FEP Amsterdam", owner =>"" },
	"ERM_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "ERM", owner =>"" },
	"ExecCmd",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "ExecCmd", owner =>"" },
	"ExecCmd_Interface",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "ExecCmd Interface", owner =>"" },
	"FSServerDLL2",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "FSServerDLL2", owner =>"" },
	"FSServerDLL2\\opcbase",	{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "FSServerDLL2", owner =>"" },
	"FWZRdd",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "FWZRdd", owner =>"" },
	"HMI",				{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "HMI", owner =>"" },
	"Hardware_SCMA",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "Hardware SCMA", owner =>"" },
	"IAS_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "IAS Interface", owner =>"" },
	"IWSSTCS",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "IWSSTCS", owner =>"" },
	"IWSSTCMngt",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "IWSSTCMngt", owner =>"" },
	"IWSSTCMngt_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "IWSSTCMngt_Interface", owner =>"" },
	"IWSSTCS_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "IWSSTCS Interface", owner =>"" },
	"IconisDPO",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "IconisDPO", owner =>"" },
	"IconisDPO_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "IconisDPO Interface", owner =>"" },
	"IconisToolBox_Interface",	{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TOOLBOX Interface", owner =>"" },
	"IconisUtilities",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "UTILITIES", owner =>"" },
	"LCS_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "LCS Interface", owner =>"" },
	"MMG_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "MMG", owner =>"" },
	"MOP",				{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "MOP", owner =>"" },
	"MOP_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "MOP Interface", owner =>"" },
	"OPCHMI_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "OPCHMI", owner =>"" },
	"OPCMDBGTW",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "OPCMDBGTW", owner =>"" },
	"OPCMDBGTW_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "OPCMDBGTW Interface", owner =>"" },
	"OPC_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "OPC Interface", owner =>"" },
	"PTD_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "PTD Interface", owner =>"" },
	"RDD_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "RDD Interface", owner =>"" },
	"RSM_U400_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "RSM U400 Interface", owner =>"" },
	"SCMAPersist",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "SCMA Persistant", owner =>"" },
	"SCMAPersist_Interface",	{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "SCMA Persistant Interface", owner =>"" },
	"SCMA_Deployment",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "SCMA Deployment", owner =>"" },
	"SOQ_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "SOQ Interface", owner =>"" },
	"SigRule_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "SIGR Interface", owner =>"" },
	"Tabs_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TABs Interface", owner =>"" },
	"TAO_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TAO Interface", owner =>"" },
	"TDS_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TDS Interface", owner =>"" },
	"TIX",				{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TIX", owner =>"" },
	"TIXToolkit",			{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TIX Toolkit", owner =>"" },
	"TIX_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TIX Interface", owner =>"" },
	"TMM_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TMM Interface", owner =>"" },
	"TOM8\\Include",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "S2K", owner =>"" },
	"TPM_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TPM Interface", owner =>"" },
	"TSY",				{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TSY", owner =>"" },
	"TSY_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TSY Interface", owner =>"" },
	"TTC_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "TTC Interface", owner =>"" },
	"Topology_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  " TOP Interface", owner =>"" },
	"TraceOPC_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "OPC Interface", owner =>"" },
	"VLSMSimulator",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "VLSM Simulator", owner =>"" },
	"VPIS",				{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "VPIS", owner =>"" },
	"VPIS_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "VPIS Interface", owner =>"" },
	"ZCI_Interface",		{sub_system => "Sw_Amsterdam,XXX",        Type => "basics",	component =>  "ZCI Interface", owner =>"" },
);
#----------------------------------------------------------------------------
# Creates ClearQuest file by component
#----------------------------------------------------------------------------
sub CreatesClearQuestComponent #(components)
{
	my (%components) = @_;

	# Initialise the default value from environment variables (depending of the project)
	$changeResquestRow{"product"}->{default_value}			= $TestUtil::clearQuestProduct;
	$changeResquestRow{"product_version"}->{default_value}	= $TestUtil::clearQuestProductVersion;

	my %ComponentByRuleList;

	# Build the description for the CR for the rule for the component
	foreach my $componentName (sort keys(%components))
	{
		foreach my $fileName (sort keys(%{$components{$componentName}}))
		{
			my $firstItemRule = 1;
			foreach my $ruleID (sort keys(%{$components{$componentName}->{$fileName}}))
			{
				my $rec = $components{$componentName}->{$fileName}->{$ruleID};

				my $result = $rec->{result};
				my $remark = $rec->{remark};

				# Calculate FILE result
				if($result eq "ERROR")
				{
					# Build the map for component and by rule
					if ($firstItemRule)
					{
						$firstItemRule = 0;
					}
					else
					{
						$ComponentByRuleList{$componentName}->{$ruleID} .= "|";
					}

					$ComponentByRuleList{$componentName}->{$ruleID} .= "File ".$fileName." : ".removeHTMLBalise($remark);
				} # ERROR
			} # for each rule in the file
		} # for each file in the component
	} # for each component

	my %changeRequestList;

	foreach my $componentName (sort keys(%ComponentByRuleList))
	{
		# Check if the component is allready know
		if (! defined $componentProperties{$componentName})
		{
			print "Unknow component for directory $componentName\n";
		}

		foreach my $ruleID (sort keys(%{$ComponentByRuleList{$componentName}}))
		{
			my $crKEY = "$componentName"."_".$ruleID;

			# Initialise the default value for the change request
			%changeRequestList = InitChangeRequest($crKEY, $componentName, %changeRequestList);

			$changeRequestList{$crKEY}->{$changeResquestRow{"headline"}->{libelle}}		= "$ruleID : $componentName";
			$changeRequestList{$crKEY}->{$changeResquestRow{"description"}->{libelle}}	= $ComponentByRuleList{$componentName}->{$ruleID};
		}
	}

	# Write the txt file with the CR for clear quest
	WriteClearQuest(%changeRequestList);
} #sub CreatesClearQuestComponent

#----------------------------------------------------------------------------
# Creates ClearQuest file
#----------------------------------------------------------------------------
sub CreatesClearQuestFile #(components)
{
	my (%components) = @_;
	my %changeRequestList;

	# Initialise the default value from environment variables (depending of the project)
	$changeResquestRow{"product"}->{default_value}			= $TestUtil::clearQuestProduct;
	$changeResquestRow{"product_version"}->{default_value}	= $TestUtil::clearQuestProductVersion;

	foreach my $componentName (sort keys(%components))
	{
		print "Component [$componentName]\n" if $DEBUG;

		# Check if the component is allready know
		if (! defined $componentProperties{$componentName})
		{
			print "Unknow component for directory $componentName\n";
		}

		foreach my $fileName (sort keys(%{$components{$componentName}}))
		{
			print "   File=[$fileName]\n" if $DEBUG;

			foreach my $ruleID (sort keys(%{$components{$componentName}->{$fileName}}))
			{
				my $rec = $components{$componentName}->{$fileName}->{$ruleID};

				my $result = $rec->{result};
				my $remark = $rec->{remark};

				print "	   Rule=[$ruleID] Result=[$result]\n" if $DEBUG;

				# Calculate FILE result
				if($result eq "ERROR")
				{
					my $crKEY = $componentName."_".$fileName."_".$ruleID;

					# Initialise the default value for the change request
					%changeRequestList = InitChangeRequest($crKEY, $componentName, %changeRequestList);

					$changeRequestList{$crKEY}->{$changeResquestRow{"headline"}->{libelle}}		= "$ruleID : $componentName - $fileName";
					$changeRequestList{$crKEY}->{$changeResquestRow{"description"}->{libelle}}	= removeHTMLBalise($remark);
				} # ERROR
			} # for each rule in the file
		} # for each file in the component
	} # for each component

	# Write the txt file with the CR for clear quest
	WriteClearQuest(%changeRequestList);
} #sub CreatesClearQuestFile

#----------------------------------------------------------------------------
# Init all record of a change resquest
#----------------------------------------------------------------------------
sub InitChangeRequest #($crKEY, $componentName, %changeRequestList)
{
	my ($crKEY, $componentName, %changeRequestList) = @_;

	my $ComponentUnknow = 1;

	if (defined $componentProperties{$componentName})
	{
		$ComponentUnknow = 0;
	}

	foreach my $CRRow (sort keys(%changeResquestRow))
	{
		my $component_property = $changeResquestRow{$CRRow}->{component_property};
		if ($ComponentUnknow or (!$component_property))
		{
			$changeRequestList{$crKEY}->{$changeResquestRow{$CRRow}->{libelle}} = $changeResquestRow{$CRRow}->{default_value};
		}
		else
		{
			$changeRequestList{$crKEY}->{$changeResquestRow{$CRRow}->{libelle}} = $componentProperties{$componentName}->{$component_property};
		}
	}# for each row of clear quest change request

	return (%changeRequestList);
} #sub InitChangeRequest

#----------------------------------------------------------------------------
# Remove the HTML balise from the detail result and replace the ; by  - 
#----------------------------------------------------------------------------
sub removeHTMLBalise #($remark)
{
	my ($remark) = @_;
	my $remarkWithoutBalise;

	my $insideBalise = 1;
	my $posRemark = 0;

	while ($posRemark < length($remark))
	{
		my $carRemark = substr($remark,$posRemark,1);
		$posRemark++;

		if ($carRemark eq '<') 
		{
			$insideBalise = 1;
		}

		if ($insideBalise == 0)
		{
			if ($carRemark eq ';')
			{
				$remarkWithoutBalise .= " - ";
			}
			elsif ($carRemark eq '"')
			{
				$remarkWithoutBalise .= " ";
			}
			else
			{
				$remarkWithoutBalise .= $carRemark;
			}
		}

		if ($carRemark eq '>')
		{
			$insideBalise = 0;
		}
	}

	return ($remarkWithoutBalise);
}

#----------------------------------------------------------------------------
# Creates ClearQuest file
#----------------------------------------------------------------------------
sub WriteClearQuest #(changeResquests)
{
	my (%changeResquests) = @_;

	my $ClearQuestFileName = $TestUtil::targetPath . "clearQuest.txt";

	print "Generate $ClearQuestFileName\n";

	open CLEARQUEST, ">$ClearQuestFileName";
	#printf CLEARQUEST "\"product\";\"headline\";\"analyst\";\"submitter\";\"key_requirements\";\"defect_detection_phase\";\"severity\";\"priority\";\"frequency\";\"product_version\";\"site\";\"State\";\"substate\";\"submitter_CR_type\";\"submitter_severity\";\"submitter_priority\";\"CR_type\";\"customer_access\";\"description\";\"sub_system\";\"component\";\"CR_category\"\n";

	# Write the line for the headers
	my $firstRow = 1;
	foreach my $CRRow (sort { $changeResquestRow{$a}->{position} <=> $changeResquestRow{$b}->{position} } keys(%changeResquestRow))
	{
		if ($firstRow)
		{
			$firstRow = 0;
		}
		else
		{
			print CLEARQUEST ";";
		}

		print CLEARQUEST "\"";
		print CLEARQUEST $changeResquestRow{$CRRow}->{libelle};
		print CLEARQUEST "\"";
	}# for each row of clear quest change request
	print CLEARQUEST "\n";

	# Write the value of the CR
	foreach my $CReq (sort keys(%changeResquests))
	{
		my $firstRow = 1;
		foreach my $CRRow (sort { $changeResquestRow{$a}->{position} <=> $changeResquestRow{$b}->{position} } keys(%changeResquestRow))
		{
			if ($firstRow)
			{
				$firstRow = 0;
			}
			else
			{
				print CLEARQUEST ";";
			}

			print CLEARQUEST "\"";
			print CLEARQUEST $changeResquests{$CReq}->{$changeResquestRow{$CRRow}->{libelle}};
			print CLEARQUEST "\"";
		}# for each row of clear quest change request

		print CLEARQUEST "\n";

	} # for each change request

	close CLEARQUEST;
} #sub CreatesClearQuestFile

#----------------------------------------------------------------------------
# Return of the package
#----------------------------------------------------------------------------

return 1;
