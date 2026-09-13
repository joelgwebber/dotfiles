require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

/**
 * @type and
 * @comparator contains
 */
if allof (address :all :comparator "i;unicode-casemap" :matches "From" [
  "*veracross.com",
  "*aischool.org",
  "*@classroom.google.com",
  "*aischool.org@hubspotfree.hs-send.com",
  "no-reply@classroom.google.com"
]) {
  fileinto "School";
}

