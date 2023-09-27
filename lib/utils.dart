String replaceEnglishWithMyanmarNumbers(String input) {
  // Define a map to hold the mapping between English and Myanmar digits
  const Map<String, String> numberMap = {
    '0': '၀',
    '1': '၁',
    '2': '၂',
    '3': '၃',
    '4': '၄',
    '5': '၅',
    '6': '၆',
    '7': '၇',
    '8': '၈',
    '9': '၉',
  };

  // Iterate through each character in the input string and replace English digits with Myanmar digits
  final StringBuffer result = StringBuffer();
  for (final char in input.split('')) {
    if (numberMap.containsKey(char)) {
      result.write(numberMap[char]);
    } else {
      result.write(char);
    }
  }

  // Return the modified string
  return result.toString();
}
