from django.http import JsonResponse
from django.shortcuts import render
from django.views.decorators.http import require_POST

from .forms import ScoreForm
from .models import Score

TOP_N = 10


def index(request):
    top_scores = Score.objects.all()[:TOP_N]
    return render(request, "game/index.html", {"top_scores": top_scores})


@require_POST
def submit_score(request):
    form = ScoreForm(request.POST)
    if form.is_valid():
        score = form.save()
        rank = Score.objects.filter(time_ms__lt=score.time_ms).count() + 1
        return JsonResponse({"ok": True, "rank": rank})
    return JsonResponse({"ok": False, "errors": form.errors}, status=400)


def leaderboard(request):
    top_scores = Score.objects.all()[:TOP_N]
    data = [{"name": s.name, "time_ms": s.time_ms} for s in top_scores]
    return JsonResponse({"scores": data})
