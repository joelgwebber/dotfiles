require ["include", "environment", "variables", "relational", "comparator-i;ascii-numeric", "spamtest"];
require ["fileinto", "imap4flags"];

# Generated: Do not run this script on spam messages
if allof (environment :matches "vnd.proton.spam-threshold" "*", spamtest :value "ge" :comparator "i;ascii-numeric" "${1}") {
    return;
}

/**
 * @type and
 * @comparator matches
 */
if allof (address :all :comparator "i;unicode-casemap" :matches "From" [
  "chipotle@email.chipotle.com",
  "noreply@github.com",
  "no-reply@github.com",
  "do-not-reply@myschoolbucks.com",
  "*.mtb.com",
  "donotreply@mail.schwab.com",
  "info@mypeachpass.com",
  "capitalone@notification.capitalone.com",
  "team@app.fullstory.com",
  "no_reply@email.apple.com",
  "id@proxyvote.com",
  "marketing@whatsyourgusto.com",
  "*mailcenter.usaa.com",
  "Communications@finance.audiusa.com",
  "*@stripe.com",
  "info@filterbuy.com",
  "thebatch@deeplearning.ai",
  "AmericanExpress@welcome.americanexpress.com",
  "info@filterbuy.com",
  "mileage.plan@ifly.alaskaair.com",
  "donotreply@cincsystems.net",
  "support@bookings.kyte.com",
  "no-reply@blender.cloud",
  "noreply@uber.com",
  "*@constellation.com",
  "receipt.noreply@samsungcheckout.com",
  "*.att-mail.com",
  "PayPal@emails.paypal.com",
  "*@notification.capitalone.com",
  "MyAccount@spectrumemails.com",
  "*worldhelp.net",
  "*hungerrush.com",
  "maccount@microsoft.com",
  "NoReply@microcenter.com",
  "no-reply@notification.equitable.com",
  "noreply@info.coned.com",
  "*@emailconed.com",
  "no-reply@opencollective.com",
  "*@actblue.com",
  "no-reply@invoiced.com",
  "hello@email.rocketmoney.com",
  "thepower@mariettaga.gov",
  "run.payroll.invoice@adp.com",
  "e-statements@mandtbank.com",
  "feedback@slack.com",
  "members@thedispatch.com",
  "*delta.com",
  "do-not-reply@indiecommerce.com",
  "cash@square.com",
  "fidelity.investments@mail.fidelity.com",
  "support@gocurb.com",
  "invoice+statements@mail.anthropic.com",
  "noreply@paymydentist.net",
  "noreply@jerseymikes.com",
  "custserv@ebills.centralhudson.com",
  "no-reply@doordash.com",
  "messenger@messaging.squareup.com",
  "no-reply@updates.citibikenyc.com",
  "no-reply@filtersfast.com",
  "*barnesandnoble.com",
  "no-reply@info.simplisafe.com",
  "googlestore-noreply@google.com",
  "noreply@olo.com",
  "order@kwickmenu.com",
  "quickbooks@notification.intuit.com",
  "walgreens@eml.walgreens.com",
  "*bestbuy.com",
  "*@wellstar.org",
  "*shop.app",
  "*stockyardburger.com",
  "*hopenergy.com"
]) {
  fileinto "Paper Trail";
}

