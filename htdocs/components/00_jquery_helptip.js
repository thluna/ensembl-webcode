/**
 * helptip - Displays a helptip on hovering an element
 **/

(function($) {

  $.helptip = function (
    el,       // element itself
    tip,      // text to be displayed on hover
    options   // options - delay, width, static (TODO)
  ) {
  
    el = $(el);
    
    if (typeof tip === 'undefined' || tip === '') {
      tip = el[0].title;
      el.removeAttr('title');
      
      if (!tip) {
        return;
      }
    }
    
    el.on({
      mouseover: function(e) {
        var el = $(this);
        var helptip = el.data('helptip');

        if (!helptip) {
          helptip = $('<div class="helptip"><div class="ht-inner">' + tip + '</div></div>').appendTo(document.body);
          el.data('helptip', helptip);

          if (!options['static']) {
            el.on({mousemove: function(e) {
              var el = $(this);
              var offset = el.data('helptip_offset');
              el.data('helptip').css({left: (offset.x + e.pageX) + 'px', top: (offset.y + e.pageY) + 'px'});
            }});
          }
        }

        helptip[0].className = 'helptip'; // this removes any 'helptip-left' or 'helptip-top' class added previously
        var pos = {x: e.pageX, y: e.pageY};

        if ($(window).height() < ((e.pageY - $(window).scrollTop()) * 2)) {
          helptip.addClass('helptip-top');
          pos.y -= helptip.height();
        }

        if ($(window).width() < ((e.pageX - $(window).scrollLeft()) * 2)) {
          helptip.addClass('helptip-left');
          pos.x -= helptip.width();
        }

        helptip.css({left: pos.x + 'px', top: pos.y + 'px'}).show();

        if (!options['static']) {
          el.data('helptip_offset', {x: pos.x - e.pageX, y: pos.y - e.pageY});
        }
      },

      mouseout: function() {
        $(this).data('helptip').hide();
      }
    });
  };

  $.fn.helptip = function (tip, options) {

    if (typeof tip === 'object') {
      options = tip;
      tip = '';
    }

    options = $.extend({ 'static': $(document.body).hasClass('ie67') }, options || {});

    return this.each(function() {
      new $.helptip(this, tip, options);
    });
  };

})(jQuery);
