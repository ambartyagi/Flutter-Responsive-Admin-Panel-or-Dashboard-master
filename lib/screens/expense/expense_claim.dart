import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:local_auth/local_auth.dart';

class ExpenseClaim extends StatefulWidget {
  const ExpenseClaim({Key? key, this.restorationId}) : super(key: key);
  final String? restorationId;
  @override
  State<ExpenseClaim> createState() => _ExpenseClaimState();
}

class _ExpenseClaimState extends State<ExpenseClaim> with RestorationMixin {
  String? dropdownValue;
  FilePickerResult? pickerResult;
  var _openResult = 'Unknown';

  String? get restorationId => widget.restorationId;
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  final RestorableDateTime _selectedDate =
      RestorableDateTime(DateTime(2021, 7, 25));
  late final RestorableRouteFuture<DateTime?> _restorableDatePickerRouteFuture =
      RestorableRouteFuture<DateTime?>(
    onComplete: _selectDate,
    onPresent: (NavigatorState navigator, Object? arguments) {
      return navigator.restorablePush(
        _datePickerRoute,
        arguments: _selectedDate.value.millisecondsSinceEpoch,
      );
    },
  );

  @override
  void initState() {
    super.initState();
    auth.isDeviceSupported().then((bool isSupported) => setState(() =>
        _supportState =
            isSupported ? _SupportState.supported : _SupportState.unsupported));
  }

  Future<void> _checkBiometrics() async {
    late bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      print(e);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
    });
  }

  Future<void> _getAvailableBiometrics() async {
    late List<BiometricType> availableBiometrics;
    try {
      availableBiometrics = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      availableBiometrics = <BiometricType>[];
      print(e);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Let OS determine authentication method',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    setState(
        () => _authorized = authenticated ? 'Authorized' : 'Not Authorized');
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason:
            'Scan your fingerprint (or face or whatever) to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticating';
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    final String message = authenticated ? 'Authorized' : 'Not Authorized';
    setState(() {
      _authorized = message;
    });
  }

  Future<void> _cancelAuthentication() async {
    await auth.stopAuthentication();
    setState(() => _isAuthenticating = false);
  }

  static Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return DatePickerDialog(
          restorationId: 'date_picker_dialog',
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          initialDate: DateTime.fromMillisecondsSinceEpoch(arguments! as int),
          firstDate: DateTime(2021),
          lastDate: DateTime(2022),
        );
      },
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
        _restorableDatePickerRouteFuture, 'date_picker_route_future');
  }

  void _selectDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = newSelectedDate;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Selected: ${_selectedDate.value.day}/${_selectedDate.value.month}/${_selectedDate.value.year}'),
        ));
      });
    }
  }

  void callback(newDropDownValue) {
    setState(() {
      this.dropdownValue = newDropDownValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Claim"),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          child: Text("Save"),
          onPressed: () {
            if (_formKey.currentState != null &&
                _formKey.currentState!.validate()) {
              _formKey.currentState?.save();
            }
          },
        ),
      ),
      body: Center(
          child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(color: Colors.black54),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              /* Positioned(
                right: -40.0,
                left: -40.0,
                child: InkResponse(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const CircleAvatar(
                    child: Icon(Icons.close),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ), */
              Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Employee",
                              )),
                          SizedBox(height: 10.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 10.0, horizontal: 10.0),
                                      hintText: 'write something',
                                      border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 32.0),
                                          borderRadius:
                                              BorderRadius.circular(5.0)),
                                      focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.grey, width: 1.0),
                                          borderRadius:
                                              BorderRadius.circular(5.0))),
                                  onChanged: (value) {
                                    //Do something with this value
                                  },
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(Icons.search)
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (Colors.black),
                        border: Border.all(color: Colors.black),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.white24,
                              blurRadius: 7,
                              spreadRadius: 5)
                        ],
                      ),
                      child: Column(
                        children: [
                          EazeworkDropDown(
                              callback: this.callback,
                              dropdownValue: dropdownValue),
                          EazeworkDropDown(
                              callback: this.callback,
                              dropdownValue: dropdownValue),
                          EazeworkDropDown(
                              callback: this.callback,
                              dropdownValue: dropdownValue),
                          EazeworkDropDown(
                              callback: this.callback,
                              dropdownValue: dropdownValue),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: (Colors.black),
                        border: Border.all(color: Colors.black),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.white24,
                              blurRadius: 7,
                              spreadRadius: 5)
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text("Select Date",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(
                                width: 15,
                              ),
                              InkWell(
                                child: Icon(Icons.calendar_month),
                                onTap: () {
                                  _authenticateWithBiometrics().whenComplete(
                                      () => _restorableDatePickerRouteFuture
                                          .present());
                                },
                              ),
                            ],
                          ),
                          EazeworkDropDown(
                              callback: this.callback,
                              dropdownValue: dropdownValue),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(30.0),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        color: (Colors.black),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.white24,
                              blurRadius: 7,
                              spreadRadius: 5)
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text("Add Supporting Documents"),
                              ElevatedButton(
                                onPressed: () => {
                                  (_authenticateWithBiometrics()
                                      .whenComplete(() => _pickFile()))
                                },
                                child: Icon(Icons.add),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (pickerResult == null)
                                _roundedRectBorderWidget,
                              if (pickerResult == null)
                                _roundedRectBorderWidget,
                              if (pickerResult != null)
                                InkWell(
                                  onTap: () =>
                                      _openFile(pickerResult!.files.first),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      color: Colors.blueGrey,
                                    ),
                                    height: 100,
                                    //width: 100,
                                    child: Expanded(
                                        child: Text(
                                            pickerResult!.files.first.name)),
                                  ),
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  void _pickFile() async {
    // opens storage to pick files and the picked file or files
    // are assigned into result and if no file is chosen result is null.
    // you can also toggle "allowMultiple" true or false depending on your need
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);

    // if no file is picked
    if (result == null) return;

    setState(() {
      pickerResult = result;
    });
  }

  Future<void> _openFile(PlatformFile file) async {
    var filePath;
    if (file != null) {
      filePath = file.path;
    } else {
      // User canceled the picker
    }
    final _result = await OpenFile.open(filePath);
    print(_result.message);

    setState(() {
      _openResult = "type=${_result.type}  message=${_result.message}";
    });
  }

  Widget get _roundedRectBorderWidget {
    return DottedBorder(
      borderType: BorderType.RRect,
      dashPattern: [6, 3, 6, 3],
      color: Colors.grey,
      radius: Radius.circular(12),
      padding: EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        child: Container(
          height: 100,
          width: 100,
          child: Icon(Icons.add),
          //color: Colors.amber,
        ),
      ),
    );
  }

  void dateController() {}
}

class EazeworkDropDown extends StatelessWidget {
  Function? callback;

  EazeworkDropDown(
      {Key? key, required this.dropdownValue, required this.callback})
      : super(key: key);

  final String? dropdownValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Text("Claim Type", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(
            width: 15,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 5.0, right: 5.0),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(3.0)),
              child: DropdownButton<String>(
                value: dropdownValue,
                hint: Text("Select Claim Type"),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, size: 22),
                //underline: SizedBox(),
                items: <String>['A', 'B', 'C', 'D'].map((String value) {
                  return new DropdownMenuItem<String>(
                    value: value,
                    child: new Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  //Do something with this value
                  callback!(newValue);
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}
