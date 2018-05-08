from django import forms
from captcha.fields import ReCaptchaField

class ContactForm(forms.Form):
    email = forms.EmailField(required=True, label='Your Email Address')
    subject = forms.CharField(required=True, label='Subject', max_length=100)
    body = forms.CharField(required=True, label='Mail text',
        widget=forms.Textarea)
    captcha = ReCaptchaField()

