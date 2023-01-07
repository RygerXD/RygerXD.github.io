function calculateTotal() {
  // Get the minutes and seconds entered by the user
  const minutes = document.getElementById("minutes").value;
  const seconds = document.getElementById("seconds").value;

  // Calculate the total number of seconds
  const totalSeconds = minutes * 60 + seconds;

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
    pricePerMinute += 5;
  }
  if (document.getElementById("lights").checked) {
    pricePerMinute += 5;
  }

  // Calculate the total cost based on the number of minutes and seconds
  const totalCost = minutes * pricePerMinute + seconds * pricePerMinute / 60;

  // Display the total cost
  document.getElementById("total").innerHTML = totalCost.toFixed(2);
}

// Add event listeners to the minutes and seconds input elements
document.getElementById("minutes").addEventListener("input", calculateTotal);
document.getElementById("seconds").addEventListener("input", calculateTotal);

// Add event listeners to the checkbox elements
document.getElementById("expertPlus").addEventListener("change", calculateTotal);
document.getElementById("expert").addEventListener("change", calculateTotal);
document.getElementById("hard").addEventListener("change", calculateTotal);
document.getElementById("mediumPlusEasy").addEventListener("change", calculateTotal);
document.getElementById("lights").addEventListener("change", calculateTotal);
