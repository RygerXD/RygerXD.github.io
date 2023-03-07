function calculateTotal() {
  // Get the minutes and seconds entered by the user
  const minutes = document.getElementById("minutes").value;
  const seconds = document.getElementById("seconds").value;

  // Set the initial price per minute to 0
  let pricePerMinute = 0;

  // Check each of the checkboxes and add the corresponding value to the price per minute
  if (document.getElementById("expertPlus").checked) {
    pricePerMinute += 20;
  }
  if (document.getElementById("expert").checked) {
    pricePerMinute += 15;
  }
  if (document.getElementById("hard").checked) {
    pricePerMinute += 10;
  }
  if (document.getElementById("mediumPlusEasy").checked) {
    pricePerMinute += 10;
  }
  if (document.getElementById("lights").checked) {
    pricePerMinute += 10;
  }

  // Calculate the total cost based on the number of minutes and seconds
  const totalCost = (minutes * pricePerMinute) + (seconds * (pricePerMinute / 60));

  // Display the total cost
  document.getElementById("total").innerHTML = `$${Math.ceil(totalCost)}`;

  // Update meta description
  document.head.querySelector('meta[property="og:description"]').content = `Total: $${Math.ceil(totalCost)}`;

  // Update Query Params
  const url = new URL(window.location.href);
  url.searchParams.set('min', `${minutes}`);
  url.searchParams.set('sec', `${seconds}`);
  for (const key of ['expertPlus', 'expert', 'hard', 'mediumPlusEasy', 'lights']) {
    if (document.getElementById(key).checked) {
      url.searchParams.set(key, 1);
    } else {
      url.searchParams.delete(key)
    }
  }
  window.history.replaceState('', '', url.href);
}

function prefillFormFromQuery() {
  // grab values from url query
  const params = new URLSearchParams(window.location.search);

  // parse & apply values to inputs
  document.getElementById('minutes').value = parseNumberParam(params.get('min')) || 4;
  document.getElementById('seconds').value = parseNumberParam(params.get('sec') || 20);
  document.getElementById('expertPlus').checked = parseBoolParam(params.get('expertPlus'));
  document.getElementById('expert').checked = parseBoolParam(params.get('expert'));
  document.getElementById('hard').checked = parseBoolParam(params.get('hard'));
  document.getElementById('mediumPlusEasy').checked = parseBoolParam(params.get('mediumPlusEasy'));
  document.getElementById('lights').checked = parseBoolParam(params.get('lights'));

  // recalculate total
  calculateTotal();
}

// numeric params
function parseNumberParam(val) {
  if (!val) return null;
  val = Number(val);
  return val && !isNaN(val) ? val : null;
}

// bool params as 1 or 0
function parseBoolParam(val) {
  if (!val) return false;
  val = Number(val);
  return val === 1;
}

// execute preill function on page load
prefillFormFromQuery();

// Add event listeners to the minutes and seconds input elements
document.getElementById("minutes").addEventListener("input", calculateTotal);
document.getElementById("seconds").addEventListener("input", calculateTotal);

// Add event listeners to the checkbox elements
document.getElementById("expertPlus").addEventListener("change", calculateTotal);
document.getElementById("expert").addEventListener("change", calculateTotal);
document.getElementById("hard").addEventListener("change", calculateTotal);
document.getElementById("mediumPlusEasy").addEventListener("change", calculateTotal);
document.getElementById("lights").addEventListener("change", calculateTotal);
