use v6.c;

use GTK::Raw::Types:ver<4>;

use GLib::DateTime;
use GTK::Builder:ver<4>;
use Zenity::Util;

class Zenity::Calendar {
  has $!dialog        is built;
  has $!timeout-delay is built;
  has $!b             is built handles(*);
  has $!p;
  has $.exit-code;

  method new (
   :$width                                 = 640,
   :$height                                = 480,
   :$date                                  = DateTime.now
   :$modal                                 = False,
   :ok(:ok_label(:$ok-label))              = 'OK',
   :cancel(:cancel_label(:$cancel-label))  = 'Cancel'
   :code(:exit_code(:$exit-code))          = 0,
   :title(:dialog_title(:$dialog-title))   = 'Calendar'
   :text(:dialog_text(:$dialog-text))      = 'Select a date',
   :format(:date_format(:$date-format)),
	 :extra_labels(:@extra-labels),
	 :delay(:timeout_delay(:$timeout-delay))
  ) {
    my $b = Zenity::Util.load_ui_file(
      <
        zenity_calendar_dialog
        zenity_calendar_box
      >
    );

    X::Zenity::InvalidBuilder.new.throw unless $b;

    my $dialog = $b<zenity_calendar_dialog>;
    $dialog.&ADD-EXTRA-LABELS($_)          with @extra-labels;
    $dialog.&SETUP-OK-BUTTON-LABEL($_)     with $ok-label;
    $dialog.&SETUP-CANCEL-BUTTON-LABEL($_) with $cancel-label;

    Zenity::Util.setup_dialog_title($dialog, $dialog-title);

    $dialog.setAttributes(
      icon-name    => 'x-office-calendar',
      default-size => ($width, $height),
      modal        => $modal
    );

    my $o = self.bless( :$dialog, :$b, :$timeout-delay );

    $dialog.Response.tap: SUB { $o.onResponse( |$*A ) }

    # cw: What does g_strcomress do?
    $b<zenity_calendar_text> = $_ with $dialog-text;
    $text.mnemonic-label     = $b<zenity_calendar>;

    $b<zenity_calendar>.select_day( GLib::DateTime.new($date) );

    $o
  }

  method builder {
    $!b;
  }

  method run {
  	$!dialog.show-dialog;
    $!dialog.&SETUP-TIMEOUT($_, $!p) with $!timeout-delay;
    $!p = Promise.new;
  }

  method onResponse ($, $_, $) {
    $!exit-code = do {
      when ZENITY_OK      { $!p.keep( $.output ); $_ }
      when ZENITY_TIMEOUT { $!p.keep( $.output ); $_ }
      when ZENITY_CANCEL  { $!p.break;            $_ }
      when ZENITY_ESC     { $!p.break;            $_ }

      default             { HANDLE_EXTRA_BUTTONS($_) }
    }
  }
}
