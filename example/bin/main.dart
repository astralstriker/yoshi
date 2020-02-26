import 'package:example/network.dart';

void main(List<String> arguments) {
  
  apiService.postsByUserId('1').catchError((e) {
    print(e.toString());
  });

}
