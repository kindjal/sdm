
/* take a big number of KB and make it pretty: 1,000 => (1 MB) */
function sizeSuffix ( n ) {
  var size = String(n).length
  var units
  var divisor
  switch(true) {
    case size < 4:
        units = 'KB'
        divisor = 1
        break
    case (size >= 4 && size < 7):
        units = 'MB'
        divisor = 1000
        break
    case (size >= 7 && size < 10):
        units = 'GB'
        divisor = 1000000
        break
    case (size >= 10 && size < 13):
        units = 'TB'
        divisor = 1000000000
        break
    case (size >= 13 && size < 16):
        units = 'PB'
        divisor = 1000000000000
        break
    case (size >= 16 && size < 19):
        units = 'EB'
        divisor = 1000000000000000
        break
  }
  // round to 1 decimal by * 10 / 10
  var shortVal = Math.round( n * 10 / divisor * 10 )
  return "(" + String( shortVal.toFixed(1) ) + " " + units + ")"
};

/* Add commas to a number */
function commify(n) {
  nStr = String(n)
  x = nStr.split('.')
  x1 = x[0]
  x2 = x.length > 1 ? '.' + x[1] : ''
  var rgx = /(\d+)(\d{3})/;
  while (rgx.test(x1)) {
    x1 = x1.replace(rgx, '$1' + ',' + '$2');
  }
  return x1 + x2;
};

