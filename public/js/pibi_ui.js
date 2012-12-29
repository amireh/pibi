/* the minimum amount of pixels that must be available for the
     the listlikes not to be wrapped */
  var list_offset_threshold = 120;
  function show_list() {
    console.log("moo")
    if ($(this).parent("[disabled],:disabled,.disabled").length > 0)
      return false;

    hide_list($("a.listlike.selected"));
    var list = $(this).next("ol");
    $(this).next("ol").show();

    if (list_offset_threshold + list.width() + list.parent().position().left + $(this).position().left >= $(window).width()) {
      list.css({ right: 0, left: 0 });
    } else {
      list.css({ left: $(this).position().left, right: 0 });
    }
      // .css("left", $(this).position().left);
    $(this).addClass("selected");
    $(this).unbind('click', show_list);
    $(this).add($(window)).bind('click', hide_list_callback);

    return false;
  }

  function hide_list_callback(e) {
    if ($(this).hasClass("listlike"))
      e.preventDefault();

    hide_list($(".listlike.selected:visible"));

    return true;
  }

  function hide_list(el) {
    console.log('hiding')
    $(el).removeClass("selected");
    $(el).next("ol").hide();
    $(el).add($(window)).unbind('click', hide_list_callback);
    $(el).bind('click', show_list);

    return true;
  }

$(function() {
  $("a.listlike:not(.selected),a[data-listlike]:not(.selected)").bind('click', show_list);
  // $("ol.listlike li:not(.sticky), ol.listlike li:not(.sticky) *, \
  //    ol[data-listlike] li:not(.sticky), ol[data-listlike] li:not(.sticky) *").click(function() {
  //   var anchor = $(this).parent().prev("a.listlike,a[data-listlike]");
  //   if (anchor.hasClass("selected")) {
  //     hide_list(anchor);
  //   }

  //   return true; // let the event propagate
  // });
})

