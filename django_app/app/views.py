from django.shortcuts import render, redirect
from .models import Login
from .forms import RegisterForm

def login_view(request):
    if request.method == 'POST':
        username = request.POST.get('username').strip()
        password = request.POST.get('password').strip()
        try:
            user = Login.objects.get(username=username)
            if user.password == password:
                request.session['username'] = username
                return redirect('home')
            else:
                return render(request, 'login.html', {'error': 'Invalid credentials'})
        except Login.DoesNotExist:
            return render(request, 'login.html', {'error': 'Invalid credentials'})
    return render(request, 'login.html')


def register_view(request):
    if request.method == 'POST':
        form = RegisterForm(request.POST)
        if form.is_valid():
            username = form.cleaned_data['username'].strip()
            password = form.cleaned_data['password'].strip()
            Login.objects.create(username=username, password=password)
            return redirect('login')
    else:
        form = RegisterForm()
    return render(request, 'register.html', {'form': form})


def home_view(request):
    username = request.session.get('username')
    if not username:
        return redirect('login')
    return render(request, 'home.html', {'username': username})


def logout_view(request):
    request.session.flush()
    return redirect('login')

