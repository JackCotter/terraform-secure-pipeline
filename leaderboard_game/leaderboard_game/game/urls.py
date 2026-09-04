from django.urls import path
from . import views

urlpatterns = [
    path("", views.index, name="index"),
    path("submit/", views.submit_score, name="submit_score"),
    path("leaderboard/", views.leaderboard, name="leaderboard"),
]
