require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

/**
 * @type and
 * @comparator ends
 */
if allof (address :all :comparator "i;unicode-casemap" :matches "From" [
  "noreply@canarymedia.com",
  "hello@theinformation.com",
  "info@theinformation.com",
  "davidroberts@substack.com",
  "hello@thedispatch.com",
  "404-media@ghost.io",
  "newsletters@nautil.us",
  "*@medium.com",
  "WallStreetJournal@t.dowjones.com",
  "Quanta@SimonsFoundation.org",
  "members@e.qz.com>",
  "newsletter@themarginalian.org",
  "noreply@e.economist.com",
  "*@substack.com",
  "Quanta@simonsfoundation.org",
  "sciencemagazine@mailings1.gtxcel.com",
  "noreply@wheresyoured.at",
  "Quanta@SimonsFoundation.org",
  "members@e.qz.com",
  "newsletter@bellingcat.com",
  "info@email.theguardian.com",
  "*ground-news.com"
]) {
  fileinto "News";
}

