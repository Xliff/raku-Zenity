use v6.c;

use NativeCall;

use GLib::Raw::Definitions;
use Pango::Raw::Definition;
use GTK::Raw::Definitions:ver<4>;
use Adwaita::Raw::Definitions;
use Zenity::Raw::Definitions;

unit package Zenity::Raw::Util;

### /home/cbwood/Projects/zenity/src/util.h

sub zenity_util_add_button (
  AdwMessageDialog $dialog,
  Str              $button_text,
  ZenityExitCode   $response_id
)
  returns GtkWidget
  is      native(zenity)
  is      export
{ * }

sub zenity_util_fill_file_buffer (
  GtkTextBuffer $buffer,
  Str           $filename
)
  returns uint32
  is      native(zenity)
  is      export
{ * }

sub zenity_util_gapp_main (GtkWindow $window)
  is      native(zenity)
  is      export
{ * }

sub zenity_util_gapp_quit (
  GtkWindow  $window,
  gpointerZenityData $data
)
  is      native(zenity)
  is      export
{ * }

sub zenity_util_gicon_from_string (Str $str)
  returns GIcon
  is      native(zenity)
  is      export
{ * }

sub zenity_util_load_ui_file (Str $widget_root)
  returns GtkBuilder
  is      native(zenity)
  is      export
{ * }

sub zenity_util_pango_font_description_to_css (PangoFontDescription $desc)
  returns Str
  is      native(zenity)
  is      export
{ * }

sub zenity_util_parse_dialog_response (Str $response)
  returns gint
  is      native(zenity)
  is      export
{ * }

sub zenity_util_return_exit_code (ZenityExitCode $value)
  returns gint
  is      native(zenity)
  is      export
{ * }

sub zenity_util_setup_dialog_title (
  gpointer   $dialog,
  gpointer
)
  is      native(zenity)
  is      export
{ * }

sub zenity_util_show_dialog (GtkWidget $widget)
  is      native(zenity)
  is      export
{ * }

sub zenity_util_show_help (CArray[Pointer[GError]] $error)
  is      native(zenity)
  is      export
{ * }

sub zenity_util_strip_newline (Str $string)
  returns Str
  is      native(zenity)
  is      export
{ * }

sub zenity_util_timeout_handle (AdwMessageDialog $dialog)
  returns uint32
  is      native(zenity)
  is      export
{ * }
