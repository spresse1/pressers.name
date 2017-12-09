from pressers_name.contact.forms import ContactForm
from django.views.generic.edit import FormView
from django.views.generic.base import TemplateView
from django.core.mail import mail_admins

class ContactView(FormView):
    template_name = 'contact/contact.html'
    form_class = ContactForm
    success_url = 'thanks'

    def form_valid(self, form):
        # This method is called when valid form data has been POSTed.
        # It should return an HttpResponse.
        mail_admins(
            "Contact form input",
            "From: " + form.cleaned_data['email'] + "\n" +
            "Subject: " + form.cleaned_data['subject'] + "\n\n" +
            form.cleaned_data['body'],
            fail_silently=False
        )
        return super(ContactView, self).form_valid(form)

class ThanksView(TemplateView):
    template_name = 'contact/thanks.html'

