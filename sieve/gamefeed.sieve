require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

/**
 * @type and
 * @comparator is
 */
if allof (address :all :comparator "i;unicode-casemap" :matches "From" [
  "newsletter@pouncelight.games",
  "hello@wholesomegames.com",
  "no-reply@email.bethesda.net",
  "*annapurnainteractive.com",
  "*@jordanmechner.com",
  "*@info.gdcevents.com",
  "*@digitaleclipse.com",
  "*howtomarketagame.com",
  "*itch.io"
]) {
    fileinto "Game Feed";
}

