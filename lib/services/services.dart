class Services {
  
  Future<bool?> isValidRecipient(String phone, String walletType) async {
    const airtelPrefixes = ['077', '074', '076'];
    const mobicashPrefixes = ['062', '065', '066'];
    if (walletType == "AIRTEL_MONEY") {
      return airtelPrefixes.any((prefix) => phone.startsWith(prefix));
    } else if (walletType == "MOOV_MONEY") {
      return mobicashPrefixes.any((prefix) => phone.startsWith(prefix));
    }
    return false; // si wallet inconnu
  }
}
