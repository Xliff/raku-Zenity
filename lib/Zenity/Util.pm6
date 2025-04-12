use v6.c;

use Zenity::Raw::Types;
use Zenity::Raw::Util;

use GLib::Timeout;
use GTK::Dialog:ver<4>;
use Adwaita::Dialog::Message;

class Zenity::Util { ... }

INIT {
  # cw: Remember to register Adwaita types in Builder!!!
}

multi sub ADD-EXTRA-LABELS ($d, *@labels) is export {
  samewith($d, @labels);
}
multi sub ADD-EXTRA-LABELS ($d, @labels) is export {
  for @labels.kv -> $k, $_ {
    when Adwaita::Dialog::Message { $d.zenity_add_button($v, $k) }
		when GTK::Dialog              { $d.add_button($v, $k)        }
	}
}

sub HANDLE_EXTRA_BUTTONS ( $response, @extra-labels = @() ) is export {
	return ZENITY_EXTRA if $response < @extra-labels.elems;

  X::Zenity::UnexpectedLocation.new.throw;
}

sub SETUP-OK-BUTTON-LABEL (
   $d,
  :ok_label(:$ok-label) = 'OK'
) is export {
  $d.set_response_label('ok', :$ok-label)
    if $d.has_response eq <ok yes>.any;
}

sub SETUP-CANCEL-BUTTON-LABEL (
   $d,
  :cancel_label(:$cancel-label) = 'Cancel'
) is export {
  $d.set_response_label('cancel', :$cancel-label)
    if $d.has_response eq <cancel no>.any;
}

sub SETUP-TIMEOUT-DELAY (
   $d,
   $p,
  :timeout_delay(:$timeout-delay) = 30,
  :$callback
) is export {
  X::Zenity::MissingCallback.new.throw without $callback;

  GLib::Timeout.add-seconds(
    $delay-timeout,
    SUB { &callback(); $p.break }
  )
}

class Zenity::Util {

  method add_button (
    AdwMessageDialog() $dialog,
    Str()              $button_text,
    Int()              $response_id
  ) {
    ZenityExitCode $r = $response_id;

    zeniy_util_add_button($dialog, $button_text, $r);
  }

  method fill_file_buffer (
    GtkTextBuffer() $buffer,
    Str()           $filename
  ) {
    zenity_util_fill_file_buffer($buffer, $filename);
  }

  method gapp_main (GtkWindow() $window) {
    zenity_util_gapp_main($window);
  }

  method gapp_quit (GtkWindow() $window) {
    zenity_util_gapp_quit($window, $data);
  }

  method gicon_from_string (Str() $str) {
    zenity_util_gicon_from_string($str);
  }

  method load_ui_file (Str() $widget_root) {
    zenity_util_load_ui_file($widget_root);
  }

  method pango_font_description_to_css (
    PangoFontDescription() $desc
  ) {
    zenity_util_pango_font_description_to_css($desc);
  }

  method parse_dialog_response (Str() $response) {
    zenity_util_parse_dialog_response($response);
  }

  method return_exit_code (Int() $value) {
    my ZenityExitCode $v = $value;

    zenity_util_return_exit_code($v);
  }

  method setup_dialog_title (AdwMessageDialog() $dialog) {
    zenity_util_setup_dialog_title($dialog, gpointer);
  }

  method show_dialog (GtkWidget() $widget) {
    zenity_util_show_dialog($widget);
  }

  method show_help (CArray[Pointer[GError]] $error = gerror) {
    clear_error;
    zenity_util_show_help($error);
    set_error($error);
  }

  method strip_newline (Str() $string) {
    zenity_util_strip_newline($string);
  }

  method timeout_handle (AdwMessageDialog() $dialog) {
    zenity_util_timeout_handle($dialog);
  }
}
