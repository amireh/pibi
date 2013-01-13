// status = ui.status;
pibi_ui = function() {

  var colors = [];
  var handlers = {
        on_entry: []
      },
      status_timer = null,
      timers = {
        autosave: null,
        sync: null,
        flash: null
      },
      theme = "",
      anime_dur = 250,
      status_shown = false,
      current_status = null,
      status_queue = [],
      animation_dur = 2500,
      pulses = {
        autosave: 30, /* autosave every half minute */
        sync: 5,
        flash: 2.5
      },
      defaults = {
        status: 1
      },
      actions = {},
      removed = {},
      action_hooks = { pages: { on_load: [] } },
      hooks = [
        // HTML5 compatibility tests
        function() {
          if (!Modernizr.draganddrop) {
            ui.modal.as_alert($("#html5_compatibility_notice"))
          }
        },

        // initialize dynamism
        function() {
          dynamism.configure({ debug: false, logging: false });

          // element tooltips
          $("a[title],span[title]").tooltip({ placement: "bottom", delay: { show: 500, hide: 100 } });
        },

        function() {
          $("[data-collapsible]").each(function() {
            $(this).append($("#collapser").clone().attr({ id: null, hidden: null }));
          });
        },

        // Togglable sections
        function() {
          $("section:not([data-untogglable])").
            find("> h1:first-child, > h2:first-child, > h3:first-child").
            addClass("togglable");

          $("section > .togglable").click(function() {
            // $(this).parent().toggle();
            $(this).siblings(":not([data-untogglable])").toggle();
            $(this).toggleClass("toggled")
          })
        },

        // disable all links attributed with data-disabled
        function() {
          $("a[data-disabled], a.disabled").click(function(e) { e.preventDefault(); return false; });
        },

        // listlike menu anchors
        function() {
          $("a.listlike:not(.selected),a[data-listlike]:not(.selected)").bind('click', show_list);
        },
        function() {
          $("input[data-linked-to],button[data-linked-to]").each(function() {
              var target = $(this).siblings("input[name^=" + $(this).attr("data-linked-to") + "]:first");
              var button = $(this);
              target.keyup(function() {
              if ($(this).attr("value").length > 0) {
                button.attr("disabled", null);
              } else {
                button.attr("disabled", "disabled");
              }
            }).keyup();
          });
        },

        // colorize balance labels (positive or negative balances)
        function() {
          $("[data-amount]").each(function() {
            $(this).addClass(parseInt($(this).html()) >= 0 ? "positive" : "negative");
          });
        },

        function() {
          if (typeof Highcharts != 'undefined') {
            colors = Highcharts.getOptions().colors;
            Highcharts.setOptions({
              credits: { enabled: false },
              title: { text: null },
              chart: {
                backgroundColor: 'rgba(255,255,255, 0)',
                borderWidth: 0,
                borderRadius: 0,
              },
              tooltip: {
                style: {
                  'padding': '10px'
                }
              },
            });
          }
        }

      ]; // end of hooks


  var month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
  var chart_options = {
    xAxis: {
      categories: month_names
    },
    // legend: false,
    // tooltip: {
    //   formatter: function() {
    //     return this.x +':<b>' + this.y + '</b>';
    //   }
    // },
    plotOptions: {
      column: {
        dataLabels: {
          enabled: true,
          style: {
            fontWeight: 'normal'
          },
          formatter: function() {
            // return pibi.format_balance(this.y);
            return parseInt(this.y);
          }
        }
      }
    }
  };
  var color_idx = -1;
  function next_color() {
    if (++color_idx == colors.length)
      color_idx = 0;
    return colors[color_idx];
  }
  /* the minimum amount of pixels that must be available for the
     the listlikes not to be wrapped */
  var list_offset_threshold = 120;
  function show_list() {
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
    $(el).removeClass("selected");
    $(el).next("ol").hide();
    $(el).add($(window)).unbind('click', hide_list_callback);
    $(el).bind('click', show_list);

    return true;
  }

  return {
    hooks: hooks,
    theme: theme,
    action_hooks: action_hooks,

    collapse: function() {
      var source = $(this);
      // log(!source.attr("data-collapse"))
      if (source.attr("data-collapse") == null)
        return source.siblings("[data-collapse]:first").click();

      if (source.attr("data-collapsed")) {
        source.siblings(":not(span.folder_title)").show();
        source.attr("data-collapsed", null).html("&minus;");
        source.parent().removeClass("collapsed");

        pagehub.settings.runtime.cf.pop_value(parseInt(source.attr("data-folder")));
        pagehub.settings_changed = true;
      } else {
        source.siblings(":not(span.folder_title)").hide();
        source.attr("data-collapsed", true).html("&plus;");
        source.parent().addClass("collapsed");

        pagehub.settings.runtime.cf.push(parseInt(source.attr("data-folder")));
        pagehub.settings_changed = true;
      }
    },

    modal: {
      as_alert: function(resource, callback) {
        if (typeof resource == "string") {

        }
        else if (typeof resource == "object") {
          var resource = $(resource);
          resource.show();
        }
      }
    },

    status: {
      clear: function(cb) {
        if (!$("#status").is(":visible"))
          return (cb || function() {})();

        $("#status").addClass("hidden").removeClass("visible");
        status_shown = false;

        if (cb)
          cb();

        if (status_queue.length > 0) {
          var status = status_queue.pop();
          return ui.status.show(status[0], status[1], status[2]);
        }
      },

      show: function(text, status, seconds_to_show) {
        if (!status)
          status = "notice";
        if (!seconds_to_show)
          seconds_to_show = defaults.status;

        // queue the status if there's one already being displayed
        if (status_shown && current_status != "pending") {
          return status_queue.push([ text, status, seconds_to_show ]);
        }

        // clear the status resetter timer
        if (status_timer)
          clearTimeout(status_timer)

        status_timer = setTimeout("ui.status.clear()", status == "bad" ? animation_dur * 2 : animation_dur);
        $("#status").removeClass("pending good bad").addClass(status + " visible").html(text);
        status_shown = true;
        current_status = status;
      },

      mark_pending: function() {
        // $(".loader").show(250);
        $(".loader").show();
      },
      mark_ready: function() {
        // $(".loader").hide(250);
        $(".loader").hide();
      }
    },

    dialogs: {
    },

    /*
     * Charts:
     *
     * A note on arguments:
     *
     *  All arguments to chart plotting functions that are documented
     *  as "data series" need to be an Array of hashes containing a 'y'
     *  key that denotes the numerical amount of the thing the chart is visualizing.
     *
     *  Example:
     *
     *    [ { y: 123 }, { y: -50.5 } ]
     *
     *  When rendering a yearly chart, 123 is expected to be Jan's Y, and -50.5 is Feb's
     *
     *  The length of the data series would be 12 in case of Yearly charts, and
     *  27-32 in case of Monthly charts.
     *
     * A @container argument is the 'id' of an element in which the chart will be rendered.
     */
    charts: {
      yearly: {

        /**
         * monthly_balance must be a data series denoting the balance for the given month.
         **/
        plot_balance: function(monthly_balance, container) {
          new Highcharts.Chart($.extend(chart_options,
          {
            chart: {
              renderTo: container,
              type: 'spline'
            },
            legend: false,
            yAxis: { title: { text: 'Balance' }
            },
            series: monthly_balance
          }));
        }, // charts.yearly_charts.plot_balance()

        /**
         * Arguments:
         *
         * yearly_savings: must be a data series (see above) containing
         * the delta of deposit and withdrawal balance of each month.
         *
         * yearly_withdrawals: must be a data series containing the *absolute*
         * withdrawal balance of each month.         *
         **/
        plot_savings: function(yearly_savings, yearly_withdrawals, container) {
          new Highcharts.Chart({
            chart: {
              renderTo: container,
              type: 'column',
              inverted: true
            },
            xAxis: { categories: month_names },
            yAxis: {
              title: {
                text: null
              }
            },
            plotOptions: {
              column: {
                stacking: 'normal',
                dataLabels: {
                  enabled: false,
                  color: (Highcharts.theme && Highcharts.theme.dataLabelsColor) || 'white'
                }
              }
            },
            series: [
              { name: 'Savings',    data: yearly_savings,     color: '#98bf0d' },
              { name: 'Spendings',  data: yearly_withdrawals, color: '#D54421' }
            ]
          });
        }
      } // charts.yearly_charts
    }, // charts

    report_error: function(err_msg) {
      ui.status.show("A script error has occured, please try to reproduce the bug and report it.", "bad");
      console.log("Script error:"); console.log(err_msg);
    },

    process_hooks: function() {
      for (var i = 0; i < ui.hooks.length; ++i) {
        ui.hooks[i]();
      }
    }
  }
}

// globally accessible instance
ui = new pibi_ui();

$(function() {
  // foreach(ui.hooks, function(hook) { hook(); });
  for (var i = 0; i < ui.hooks.length; ++i) {
    ui.hooks[i]();
  }
})