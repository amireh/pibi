pibi = function() {

  return {
    natural_join: function(ary, delim, last_delim, affixes) {
      var c = ''
      for (var i = 0; i < ary.length; ++i) {
        var s = ary[i];
        var affixed_s = affixes.length == 0 ? s : affixes[0] + s + affixes[1];
        var d = '';

        if (i == 0)
          d = '';
        else if (i == ary.length - 1)
          d = last_delim;
        else
          d = delim;

        c += d + affixed_s
      }
      return c;
    }
  }
}

// globally accessible instance
pibi = new pibi();
