# Use AWS Lambda Python 3.9 base image
FROM public.ecr.aws/lambda/python:3.9

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy the app directory to the Lambda task directory
COPY app /var/task/app

# Copy the .env file to the root of the task directory
COPY .env /var/task/.env

# Set the CMD to your handler (app.main.handler)
CMD ["app.main.handler"] 