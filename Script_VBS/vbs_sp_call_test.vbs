Const dbServer = "DESKTOP-2F8QFJM"
Const dbUserId = "DiStor_User_exec"
Const dbCatalog = "DiscontStores"
Const dbPassword = "123"

Const adCmdStoredProc = 4
Const adInteger = 3
Const adVarWChar = 202
Const adLongVarWChar = 203
Const adDate = 7
Const adParamInput = &H0001
Const adParamOutput = &H0002
Const adParamReturnValue = &H0004

Dim par_d_start, par_d_end, par_d_part, par_ObjectName
Dim adoRecordSet
Dim xError

par_d_start = "2021-01-01"
par_d_end = "2021-06-30"
par_d_part = "w"
par_ObjectName = "dep2"

Set adoSQLConnection = CreateObject("ADODB.Connection")

adoSQLConnection.Open _
    "Provider=SQLOLEDB;Data Source=" & dbServer & ";" & _
    "Trusted_Connection=No;Initial Catalog=" & dbCatalog &";" & _
    "User ID=" & dbUserId & ";Password=" & dbPassword & ";"

Set adoSQLCmdParam = CreateObject("ADODB.Command")
Set adoRecordSet = CreateObject("ADODB.Recordset")

With adoSQLCmdParam
    Set .ActiveConnection = adoSQLConnection
    .CommandText = "sp_query_availability_datepart"
    .CommandType = adCmdStoredProc
    .Parameters.Append .CreateParameter("RETURN_VALUE", _
        adInteger, adParamReturnValue)
    .Parameters.Append .CreateParameter("@date_start", _
        adDate, adParamInput,,par_d_start)
    .Parameters.Append .CreateParameter("@date_end", _
        adDate, adParamInput,,par_d_end)
    .Parameters.Append .CreateParameter("@date_part", _
        adVarWChar, adParamInput,1,par_d_part)
    .Parameters.Append .CreateParameter("@ObjectName", _
        adVarWChar, adParamInput,50,par_ObjectName)

    .Execute
    
    xError = .Parameters(0).Value
    
    If (xError <> 1) Then
        adoRecordSet.close
        adoSQLConnection.close
    Else
        Set adoRecordSet = .Execute
    End If
End With

If (xError = 1) Then
    Wscript.Echo xError
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
Else
    Wscript.Echo "xError"
End If    