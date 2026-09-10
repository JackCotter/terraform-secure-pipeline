from django import forms
from django.utils.html import strip_tags
from .models import Score


class ScoreForm(forms.ModelForm):
    class Meta:
        model = Score
        fields = ["name", "time_ms"]

    def clean_name(self):
        name = self.cleaned_data["name"].strip()
        
        if not name:
            raise forms.ValidationError("Name Cannot be Empty")

        # Strip any HTML Tags, no reason to be in name
        cleaned = strip_tags(name)

        if len(cleaned) > 20 :
            raise forms.ValidationError("Name must be 20 characters or less")

        return cleaned

    def clean_time_ms(self):
        time_ms = self.cleaned_data["time_ms"]
        # Sanity bound — a real human reflex click will never be this fast/slow.
        # Rejects obviously spoofed/garbage submissions without needing auth.
        if time_ms < 50 or time_ms > 10000:
            raise forms.ValidationError("Score out of plausible range.")
        return time_ms
