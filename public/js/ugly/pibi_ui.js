function show_list(){console.log("moo");if($(this).parent("[disabled],:disabled,.disabled").length>0)return!1;hide_list($("a.listlike.selected"));var e=$(this).next("ol");return $(this).next("ol").show(),list_offset_threshold+e.width()+e.parent().position().left+$(this).position().left>=$(window).width()?e.css({right:0,left:0}):e.css({left:$(this).position().left,right:0}),$(this).addClass("selected"),$(this).unbind("click",show_list),$(this).add($(window)).bind("click",hide_list_callback),!1}function hide_list_callback(e){return $(this).hasClass("listlike")&&e.preventDefault(),hide_list($(".listlike.selected:visible")),!0}function hide_list(e){return console.log("hiding"),$(e).removeClass("selected"),$(e).next("ol").hide(),$(e).add($(window)).unbind("click",hide_list_callback),$(e).bind("click",show_list),!0}var list_offset_threshold=120;$(function(){$("a.listlike:not(.selected),a[data-listlike]:not(.selected)").bind("click",show_list),$("[data-amount]").each(function(){$(this).addClass(parseInt($(this).html())>=0?"positive":"negative")})});