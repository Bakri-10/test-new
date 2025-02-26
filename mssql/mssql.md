<p align="left" height="70%" width="100%">

# 5. Azure mssql server Creation

<P> Azure mssql server with database will be created with this workflow/github actions</p>

<br>

## GitHub Workflow Fields/Parameters
<p align="left" height="70%" width="100%">

|	 Field Name 	|	 Parameter Name	|	 Type 	|	Default Value 	|	 Values Supported 	|	Required	|	Rules/Conditions	|
|	:-------------------------------   	|	 :-------------------------------   	|	 :-------------------------------   	|	 :-------------------------------   	|	 :-------------------------------   	|	:-------------------------------   	|	:-------------------------------   	|
|	Subscription Name	|	Subscription	|	Text 	|	Empty	|	Subscription Name	|	$${\color{Red}Yes}$$ 	|	N/A	|
|	Request Type	|	RequestType	|	Dropdown 	|	Create	|	Create,update,delete	|	$${\color{Red}Yes}$$ 	|	N/A	|
|	Location	|	location	|	Dropdown	|	eastus2	|	Eastus2,centralus,ukwest,uksouth	|	$${\color{Red}Yes}$$ 	|		|
|	Environment	|	environment	|	Dropdown	|	Dev	|	Dev,qa,UAT,Prod	|	$${\color{Red}Yes}$$ 	|	Create Environment names in github with same values as mentioned in "Values supported column	|
|	Purpose	|	purpose	|	Text	|	Empty	|	3-5 chars of purpose	|	$${\color{Red}Yes}$$ 	|	<span style="color:blue"><i>Specify purpose in 3-5 characters</i></span>	|
|	Enter the subnet name for DB end points	|	subnetname	|	Text	|	Empty	|	subnet names that are not delegated	|	$${\color{Red}Yes}$$ 	|	  <span style="color:Red"><i>Enter subnet names which is not delegated any other resource</i></span>	|
|	Specify Collation of the database	|	dbcollation	|	Text	|	SQL_Latin1_General_CP1_CI_AS	|	All the collations supported by Azure	|	$${\color{orange}Optional}$$ 	|	Default is "SQL_Latin1_General_CP1_CI_AS". Please specify if a different config is desired.	|
|	SKU_NAME used by database	|	skuname	|	Dropdown	|	S0	|	S0,P2,Basic,Elasticpool,BC_Gen5_2,HS_Gen4_1,GP_S_Gen5_2,DW100c,DS100	|	$${\color{orange}Optional}$$ 	|	Default is "S0". Please specify if a different config is desired.	|
|	Zone redundancy	|	zoneredundancy	|	Dropdown	|	FALSE	|	TRUE,FALSE	|	$${\color{Orange}Optional}$$ 	|	Default is "false". 	|


</p>

</p>