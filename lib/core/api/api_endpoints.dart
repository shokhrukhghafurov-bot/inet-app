class ApiEndpoints {
  static const authCode = '/auth/code';
  static const authRefresh = '/auth/refresh';
  static const authMe = '/auth/me';
  static const authLogout = '/auth/logout';

  static const appConfig = '/app/config';
  static const plans = '/plans';
  static const subscriptionMine = '/subscriptions/me';
  static const devices = '/devices';
  static const registerDevice = '/devices/register';
  static const locations = '/locations';
  static const locationsStatus = '/locations/status';

  static String vpnConfig(String locationCode) => '/vpn/config/' + locationCode;
}
