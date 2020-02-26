
import 'package:yoshi/yoshi.dart';

part 'api.g.dart';

@YoshiService()
abstract class Api {

  @Get('posts')
  Future<Call> postsByUserId(@Query('userId') String userId); 

}
