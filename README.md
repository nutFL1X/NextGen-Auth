# NextGen Authentication
NextGen Authentication is a **next-generation secure login system** that replaces static passwords with **dynamic, time-rotating, biometric-derived passwords** using cancellable fingerprint templates.
This monorepo contains **all three major components** of the solution:
- **Web Server (Node.js)** – fingerprint capturing, template matching, and rotating password validation  
- **Flutter Mobile App** – pairs with the website and generates synchronized rotating passwords  
- **SecuGen Bridge** – native fingerprint SDK bridge enabling scanner communication with the website  

## License
This project is licensed under CC BY-NC-ND 4.0.  
You may not use, modify, or redistribute this code without permission.
