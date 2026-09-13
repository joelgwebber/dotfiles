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
  "inbox@ramclin.com",
  "emailadmin@chronogram.com",
  "*@longnow.org",
  "hello@deeplearning.ai",
  "neighbors@meetingpark.org",
  "notifications@m.teachable.com",
  "newsletters@bookshop.org",
  "info@events.bowerypresents.com",
  "announcements@aaas.sciencepubs.org",
  "hi@veryspecialgames.com",
  "tim@librarything.com",
  "*@23andme.com",
  "info@atlasobscura.com",
  "*@email.amnh.org",
  "*@thehighline.org",
  "*@transistor.fm",
  "emails@songkick.com",
  "newsletter@brainpickings.org",
  "bingo@patreon.com",
  "gdc@info.gdcevents.com",
  "wired@newsletters.wired.com",
  "*@eml.livenation.com",
  "collaborate@kompoz.com",
  "editor@eff.org",
  "hello@modular.com",
  "notifications@artstation.com",
  "info@immersed.com",
  "noreply@gtalumni.org",
  "met@mail.metmuseum.org",
  "support@explodingkittens.com",
  "no-reply@blender.cloud",
  "aivalley@mail.beehiiv.com",
  "*@info.focusentnews.com",
  "events@lists.propublica.net",
  "chrisz@howtomarketagame.com",
  "aaas-noreply@rhfulfillment.com",
  "no-reply@spotify.com",
  "info@rockstargallery.net",
  "newsletter@themarginalian.org",
  "marctanjeloff@astrowest.com",
  "aso.information@atlantasymphony.org",
  "acm_mem6@hq.acm.org",
  "*email.remarkable.com",
  "events@eff.org",
  "*connectedcommunity.org",
  "*mail.gatech.edu",
  "*cc.gatech.edu",
  "*gamehistory.org",
  "hey@mail.you.com",
  "no-reply@kickstarter.com",
  "members@arc.net",
  "*bsky.app",
  "*eml.mozilla.org",
  "sales@*lucidmotors.com",
  "ancestry@email.ancestry.com",
  "*musora.com",
  "hi@follow.it",
  "*squaremktg.com"
]) {
    fileinto "Feed";
}

