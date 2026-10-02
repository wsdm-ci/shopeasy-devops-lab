// ShopEasy — checkout logic
// ------------------------------------------------------------
// LIVE DEMO: change these two lines, then update the banner in index.html.
const VALID_CODE = "CLOUD20";
const BASE_PRICE = 25000;
const DISCOUNT_RATE = 0.20;
// ------------------------------------------------------------

// Grab the page elements we need
const codeInput = document.getElementById("code-input");
const applyBtn = document.getElementById("apply-btn");
const checkoutBtn = document.getElementById("checkout-btn");
const copyBtn = document.getElementById("copy-btn");
const message = document.getElementById("message");
const discountRow = document.getElementById("discount-row");
const discountAmount = document.getElementById("discount-amount");
const totalAmount = document.getElementById("total-amount");
const itemPrice = document.getElementById("item-price");
const promoCode = document.getElementById("promo-code");
const promoPercent = document.getElementById("promo-percent");

// Turn 25000 into "₦25,000"
function formatNaira(amount) {
  return "₦" + amount.toLocaleString("en-NG");
}

// Check the typed code and update the order summary
function applyDiscount() {
  const typed = codeInput.value.trim().toUpperCase();

  if (typed === VALID_CODE) {
    const discount = BASE_PRICE * DISCOUNT_RATE;
    discountRow.hidden = false;
    discountAmount.textContent = "-" + formatNaira(discount);
    totalAmount.textContent = formatNaira(BASE_PRICE - discount);
    message.textContent = "Discount applied successfully.";
    message.className = "message success";
  } else {
    discountRow.hidden = true;
    totalAmount.textContent = formatNaira(BASE_PRICE);
    message.textContent = "That code is not valid. Try " + VALID_CODE + ".";
    message.className = "message error";
  }
}

// Show a small pop-up message for 3 seconds
let toastTimer;
function showToast(text) {
  const toast = document.getElementById("toast");
  toast.textContent = text;
  toast.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(function () {
    toast.classList.remove("show");
  }, 3000);
}

// Copy the promo code to the clipboard
function copyCode() {
  const done = function () { showToast("Code " + VALID_CODE + " copied to clipboard."); };
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(VALID_CODE).then(done);
  } else {
    // Fallback: the site runs on plain http:// on EC2, where the clipboard API is blocked
    const temp = document.createElement("textarea");
    temp.value = VALID_CODE;
    document.body.appendChild(temp);
    temp.select();
    document.execCommand("copy");
    document.body.removeChild(temp);
    done();
  }
}

// Set the starting prices on the page
itemPrice.textContent = formatNaira(BASE_PRICE);
totalAmount.textContent = formatNaira(BASE_PRICE);

// Banner text is generated from the constants, so it can never disagree with the checkout
promoCode.textContent = VALID_CODE;
promoPercent.textContent = Math.round(DISCOUNT_RATE * 100) + "%";

// Wire up the buttons
applyBtn.addEventListener("click", applyDiscount);
codeInput.addEventListener("keydown", function (event) {
  if (event.key === "Enter") applyDiscount();
});
copyBtn.addEventListener("click", copyCode);
checkoutBtn.addEventListener("click", function () {
  showToast("Demo checkout complete — no payment was processed.");
});
