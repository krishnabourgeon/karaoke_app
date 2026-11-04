import 'package:karaoke_app/provider/auth_provider.dart';
import 'package:karaoke_app/provider/upload_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';


class MultiProviderList {
  static List<SingleChildWidget> providerList = [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => UploadProvider())
  ];
}
