const pad = document.getElementById("pad");
const readout = document.getElementById("readout");
const submitPanel = document.getElementById("submit-panel");
const scoreForm = document.getElementById("score-form");
const timeInput = document.getElementById("time_ms");
const submitMsg = document.getElementById("submit-msg");
const leaderboardList = document.getElementById("leaderboard-list");

let state = "idle"; // idle -> waiting -> go
let goAt = 0;
let timeoutId = null;

function reset(message) {
  state = "idle";
  pad.dataset.state = "idle";
  pad.textContent = "Click to start";
  readout.textContent = message || "";
}

pad.addEventListener("click", () => {
  if (state === "idle") {
    state = "waiting";
    pad.dataset.state = "waiting";
    pad.textContent = "Wait for green…";
    readout.textContent = "";
    const delay = 1000 + Math.random() * 2500;
    timeoutId = setTimeout(() => {
      state = "go";
      goAt = performance.now();
      pad.dataset.state = "go";
      pad.textContent = "Click now!";
    }, delay);
  } else if (state === "waiting") {
    clearTimeout(timeoutId);
    reset("Too soon — wait for green next time.");
  } else if (state === "go") {
    const elapsed = Math.round(performance.now() - goAt);
    reset(`${elapsed}ms — enter a name to save it.`);
    timeInput.value = elapsed;
    submitPanel.hidden = false;
  }
});

function getCookie(name) {
  const match = document.cookie.match(new RegExp("(^| )" + name + "=([^;]+)"));
  return match ? decodeURIComponent(match[2]) : null;
}

scoreForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const formData = new FormData(scoreForm);
  try {
    const res = await fetch("/submit/", {
      method: "POST",
      headers: { "X-CSRFToken": getCookie("csrftoken") },
      body: formData,
    });
    const data = await res.json();
    if (data.ok) {
      submitMsg.textContent = `Saved — rank #${data.rank}.`;
      await refreshLeaderboard();
      submitPanel.hidden = true;
      scoreForm.reset();
    } else {
      submitMsg.textContent = Object.values(data.errors).flat().join(" ");
    }
  } catch (err) {
    submitMsg.textContent = "Couldn't save score — try again.";
  }
});

async function refreshLeaderboard() {
  const res = await fetch("/leaderboard/");
  const data = await res.json();
  leaderboardList.innerHTML = "";
  if (data.scores.length === 0) {
    leaderboardList.innerHTML = '<li class="lb-empty">No scores yet — be the first.</li>';
    return;
  }
  for (const s of data.scores) {
    const li = document.createElement("li");
    li.innerHTML = `<span class="lb-name"></span><span class="lb-time">${s.time_ms}ms</span>`;
    li.querySelector(".lb-name").textContent = s.name; // textContent, not innerHTML — avoids XSS
    leaderboardList.appendChild(li);
  }
}
