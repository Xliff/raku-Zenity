use v6.c;

use GTK::Raw::Types:ver<4>;

use GTK::Builder:ver<4>;
use Zenity::Util;

class Zenity::Entry {
  has $!dialog        is built;
  has $!timeout-delay is built;
  has $!b             is built handles(*);
  has $!p;
  has $.exit-code;

  method new (
   :$width                                             = 640,
   :$height                                            = 480,
   :$modal                                             = False,
   :ok(:ok_label(:$ok-label))                          = 'OK',
   :cancel(:cancel_label(:$cancel-label))              = 'Cancel'
   :code(:exit_code(:$exit-code))                      = 0,
   :title(:dialog_title(:$dialog-title))               = 'Calendar'
   :text(:dialog_text(:$dialog-text))                  = 'Select a date',
   :hide(:hide_text(:$hide-text))                      = False,
   :entry_text(:$entry-text),
   :format(:date_format(:$date-format)),
	 :extra_labels(:@extra-labels),
	 :delay(:timeout_delay(:$timeout-delay)),
   :data(:entry_data(:@entry-data))          is copy,
  ) {
    my $b = Zenity::Util.load_ui_file(
      <
        zenity_entry_dialog
        zenity_entry_box
      >
    );

    X::Zenity::InvalidBuilder.new.throw unless $b;

    my $dialog = $b<zenity_entry_dialog>;
    $dialog.&ADD-EXTRA-LABELS($_)          with @extra-labels;
    $dialog.&SETUP-OK-BUTTON-LABEL($_)     with $ok-label;
    $dialog.&SETUP-CANCEL-BUTTON-LABEL($_) with $cancel-label;

    my $o = self.bless( :$dialog, :$b, :$timeout-delay );
    $dialog.Response.tap: SUB { $o.onResponse( $*A ) }

    @entry-data.unshift($_) with $entry-text;

    my ($vbox, $text) = $b<vbox4 zenity_entry_text>;
    $text.set_text_with_mnemonic($_) with $dialog-text;

    my $entry;
    if +@entry-data > 1 {
      $entry = GTK::ComboBox::Text.new;

      my $child = $entry.child;

      $entry.append-text($_) for @entry-data;
      $entry.active = 0 with $entry-text;

      $child.Activate.tap: SUB { $dialog.emit('activate-default') }
    } else {
      $entry  = GTK::Entry.new;

      my $buffer = $entry.buffer;

      $entry.activates-default = True;

      $entry.text       = $_   with $entry-text;
      $entry.visibility = .not with $hide-text;
    }

    $vbox.append($entry);
    $text.set_mnemonic_widget($entry);

    $o;
  }

  method builder {
    $!b;
  }

  method run {
    $!dialog.show-dialog;
    $dialog.&SETUP-TIMEOUT($_, $!p) with $!timeout-delay;
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
