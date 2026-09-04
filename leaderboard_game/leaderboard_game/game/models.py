from django.core.validators import RegexValidator, MinValueValidator
from django.db import models

name_validator = RegexValidator(
    regex=r"^[A-Za-z0-9 _-]{1,20}$",
    message="Display name must be 1-20 characters: letters, numbers, spaces, - or _ only.",
)


class Score(models.Model):
    """A single leaderboard entry. Intentionally minimal — no accounts,
    no email, no IP storage. 'name' is a freely-chosen display name,
    not a verified identity."""

    name = models.CharField(max_length=20, validators=[name_validator])
    time_ms = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["time_ms"]  # lower reaction time = better

    def __str__(self):
        return f"{self.name}: {self.time_ms}ms"
