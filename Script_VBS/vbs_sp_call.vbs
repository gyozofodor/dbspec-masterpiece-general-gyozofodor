
'CREATE or ALTER PROCEDURE my_getParam
'	@paramName nvarchar(50),
'	@paramValue nvarchar(100) output
'AS
'	SET NOCOUNT ON
'	SET @paramValue = (SELECT @paramName + '_xxx')
'	RETURN 10
'GO

Const dbServer = "DESKTOP-2F8QFJM"
Const dbUserId = "DiStor_User_exec"
Const dbCatalog = "DiscontStores"
Const dbPassword = "123"

Const adCmdStoredProc = 4
Const adInteger = 3
Const adVarWChar = 202
Const adParamInput = &H0001
Const adParamOutput = &H0002
Const adParamReturnValue = &H0004

Dim parmname,parmval,x

parmname = "runScript"

Set adoSQLConnection = CreateObject("ADODB.Connection")

adoSQLConnection.Open _
    "Provider=SQLOLEDB;Data Source=" & dbServer & ";" & _
    "Trusted_Connection=No;Initial Catalog=" & dbCatalog &";" & _
    "User ID=" & dbUserId & ";Password=" & dbPassword & ";"

Set adoSQLCmdParam = CreateObject("ADODB.Command")
Set adoRecordSet = CreateObject("ADODB.Recordset")

With adoSQLCmdParam
    Set .ActiveConnection = adoSQLConnection
    .CommandText = "my_getParam"
    .CommandType = adCmdStoredProc
    .Parameters.Append .CreateParameter("RETURN_VALUE", _
        adInteger, adParamReturnValue )
    .Parameters.Append .CreateParameter("@paramName", _
        adVarWChar, adParamInput,50,parmname)

    .Parameters.Append .CreateParameter("@paramValue", _
        adVarWChar, adParamOutput,100)
    .Execute
    parmval = .Parameters(2).Value
    'Wscript.Echo .Parameters(0).Value
End With


' Create an instance of Excel and add a workbook
    Set xlApp = CreateObject("Excel.Application")
    Set xlWb = xlApp.Workbooks.Add
    Set xlWs = xlWb.Worksheets("Sheet1")

' Display Excel and give user control of Excel's lifetime
    xlApp.Visible = False
    xlApp.UserControl = True

' Copy the recordset to the worksheet, starting in cell A2
    xlWs.Cells(2, 1).CopyFromRecordset adoRecordSet

adoRecordSet.close
adoSQLConnection.close

' Release Excel references
    'objWorkbook.SaveAs(strFileName)
    xlWb.Save
    xlWb.Close
    xlApp.Quit
    
    Set xlWs = Nothing
    Set xlWb = Nothing

    Set xlApp = Nothing

