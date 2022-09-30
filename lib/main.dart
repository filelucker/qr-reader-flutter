import 'package:barcode_scan2/gen/protos/protos.pb.dart';
import 'package:barcode_scan2/model/android_options.dart';
import 'package:barcode_scan2/model/scan_options.dart';
import 'package:barcode_scan2/platform_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_reader_flutter/provider/data_provider.dart';
import 'package:qr_reader_flutter/utils/simple_vcard.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/src/provider.dart';
import 'package:provider/src/change_notifier_provider.dart';
import 'package:provider/src/consumer.dart';

import 'db/database.dart';
import 'entity/person.dart';

GetIt locator = GetIt.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database =
      await $FloorAppDatabase.databaseBuilder('qr_database.db').build();
  locator.registerLazySingleton(() => database);

  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DataProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ScanResult? scanResult;

  final _flashOnController = TextEditingController(text: 'Flash on');
  final _flashOffController = TextEditingController(text: 'Flash off');
  final _cancelController = TextEditingController(text: 'Cancel');

  var _aspectTolerance = 0.00;
  var _numberOfCameras = 0;
  var _selectedCamera = -1;
  var _useAutoFocus = true;
  var _autoEnableFlash = false;

  static final _possibleFormats = BarcodeFormat.values.toList()
    ..removeWhere((e) => e == BarcodeFormat.unknown);

  List<BarcodeFormat> selectedFormats = [..._possibleFormats];

  late DataProvider provider;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () async {
      _numberOfCameras = await BarcodeScanner.numberOfCameras;
      setState(() {});
    });
    provider = Provider.of<DataProvider>(context, listen: false);

    provider.getInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Consumer<DataProvider>(
        builder: (context, value, child) {
          if (value.qrList!.isNotEmpty) {
            return ListView.builder(
                itemCount: provider.qrList!.length,
                itemBuilder: (BuildContext context, int index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        children: [
                          Text("${provider.qrList![index].date}"),
                          Text("${provider.qrList![index].name.toString().replaceAll('[', '').replaceAll(']', '')}"),
                          Text("${provider.qrList![index].phone}"),
                          Text("${provider.qrList![index].url.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', '')}"),
                        ],
                      ),
                    ),
                  );
                });
          }else{
            return Center(child: Text('Scan QR Code'),);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scan,
        tooltip: 'QR Scan',
        child: const Icon(Icons.camera_alt),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<void> _scan() async {
    try {
      final result = await BarcodeScanner.scan(
        options: ScanOptions(
          strings: {
            'cancel': _cancelController.text,
            'flash_on': _flashOnController.text,
            'flash_off': _flashOffController.text,
          },
          restrictFormat: selectedFormats,
          useCamera: _selectedCamera,
          autoEnableFlash: _autoEnableFlash,
          android: AndroidOptions(
            aspectTolerance: _aspectTolerance,
            useAutoFocus: _useAutoFocus,
          ),
        ),
      );
      setState(() {
        print('result+++++++++++' + result.rawContent);
        if(result.rawContent.contains('VCARD')){
        VCard vc = VCard(result.rawContent);
        print('result+++++++++++' + vc.name.toString());
        print('result+++++++++++' + vc.typedURL.toString());
        print('result+++++++++++' + vc.telephone);
        Person p = new Person();
        p.url = vc.typedURL.toString();
        p.phone = vc.telephone.toString();
        p.name = vc.name.toString();
        p.email = vc.email.toString();
        provider.saveData(p);
        }
      });
      // setState(() => scanResult = result );
    } on PlatformException catch (e) {
      setState(() {
        scanResult = ScanResult(
          type: ResultType.Error,
          format: BarcodeFormat.unknown,
          rawContent: e.code == BarcodeScanner.cameraAccessDenied
              ? 'The user did not grant the camera permission!'
              : 'Unknown error: $e',
        );
      });
    }
  }
}
