use v6.c;

use Zenity::Raw::Types;

use GTK::Settings:ver<4>;
use Zenity::Util;

class Zenity::Msg {
  has $!dialog        is built;
  has $!timeout-delay is built;
  has $!b             is built handles(*);
  has $!p;
  has @!extras;
  has $.exit-code;

  method builder {
    $!b;
  }

  method new {
    :title(:dialog_title(:$dialog-title))             = 'Scale',
	  :ok(:ok_label(:$ok-label))                        = 'OK',
	  :cancel(:cancel_label(:$cancel-label))            = 'Cancel',
    :w(:$width)                                       = 640,
    :h(:$height)                                      = 480,
    :v(:val(:$value))                                 = 0,
    :min(:min_value(:$min-value))                     = 0,
    :max(:max_value(:$max-value))                     = 100,
    :$step                                            = 1,
    :$modal                                           = False,
    :hide(:hide_value(:$hide-value))                  = False,
    :exit_code(:$exit-code);
    :delay(:timeout_delay(:$timeout-delay)),
    :extras(:extra_labels(:@extra-labels),
    :text(:dialog_text(:$dialog-text)),
    :icon(:dialog_icon(:$dialog-icon)),
	  :part(:partial(:print_partial(:$print-partial)))
  ) {
    my $b = Zenity::Util.load_ui_file(
      <
        zenity_scale_dialog
        zenity_scale_box
      >
    );

    X::Zenity::InvalidBuilder.new.throw unless $b;

    my ($dialog, $scale, $text) = $b<
      zenity_scale_dialog
      zenity_scale_hscale
      zenity_scale_text
    >;

    X::Zenity::InvalidValues.new(
      message => 'Maximum value must be greater than minimum value.'
    ).throw unless $min-value < $max-value;

    X::Zenity::InvalidValues.new(
      message => 'Value out of range!'
    ).throw unless $value ~~ $min-value .. $max-value;

    my $o = self.bless( :$dialog, :$b, :$timeout-delay );

    $dialog.setAttributes(
      default-size => ($width, $height),
      modal        => $modal
      icon-name    => "dialog-question"
    );

    $dialog.Response.tap: SUB { $o.onResponse( $*A ) }

    $text.markup = $_ with $dialog-text;

    $scale.setAttributes(
       range      => $min-value .. $max-value,
       value      => $value,
       increments => $step
      (draw-value => .not with $hide-value)
    );

    $dialog.&ADD-EXTRA-LABELS($_)          with @extra-labels;
    $dialog.&SETUP-OK-BUTTON-LABEL($_)     with $ok-label;
    $dialog.&SETUP-CANCEL-BUTTON-LABEL($_) with $cancel-label;

    if $print-partial {
      $scale.Value-Changed.tap: SUB { $o.onValueChanged($scale) }
    }

    Zenity::Util.setup_dialog_title($dialog, $dialog-title);
  }

  method run {
    $!dialog.show-dialog;
    $!dialog.&SETUP-TIMEOUT($_, $!p) with $!timeout-delay;
    $!p = Promise.new;
  }

  method onValueChanged ($scale) {
    $scale.value.fmt('%.0f').say;
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

  method run {
    $!dialog.show-dialog;
    $!dialog.&SETUP-TIMEOUT($_, $!p) with $!timeout-delay;
    $!p = Promise.new;
  }

}
